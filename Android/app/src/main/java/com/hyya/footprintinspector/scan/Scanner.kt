// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

package com.hyya.footprintinspector.scan

import android.app.Application
import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.hyya.footprintinspector.catalogue.Catalogue
import com.hyya.footprintinspector.catalogue.CheckUp
import com.hyya.footprintinspector.model.OverallScore
import com.hyya.footprintinspector.model.Finding
import com.hyya.footprintinspector.model.FootprintScore
import com.hyya.footprintinspector.model.Reading
import com.hyya.footprintinspector.model.Section
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.security.MessageDigest
import java.util.UUID

/** Reads one group of signals. Must never prompt; permission readers return nothing until granted. */
fun interface Reader {
    suspend fun read(context: Context): List<Reading>
}

enum class Phase { IDLE, SCANNING, DONE }

/** Runs the scan and holds the results in memory. Only scrambled markers are saved. */
class Scanner(app: Application) : AndroidViewModel(app) {
    var phase by mutableStateOf(Phase.IDLE); private set
    var progress by mutableStateOf(0f); private set
    var readings by mutableStateOf<Map<String, Reading>>(emptyMap()); private set
    var comparison by mutableStateOf<Comparison?>(null); private set

    val history = HistoryStore(app)

    val findings: List<Finding>
        get() = Catalogue.list.mapNotNull { d -> readings[d.id]?.let { Finding(d, it) } }

    fun findings(section: Section) = findings.filter { it.definition.section == section }

    /** What any app can read with no prompt: everything except findings from granted permissions. */
    val findingsWithoutAsking: List<Finding>
        get() = findings.filter { it.definition.section.group != com.hyya.footprintinspector.model.Group.PERMISSION }

    val concerning: List<Finding> get() = findings.filter { it.isConcerning }
    val score: FootprintScore get() = FootprintScore.of(findings)

    private val prefs = app.getSharedPreferences("app", Context.MODE_PRIVATE)
    /** Store screenshots keep nothing between runs. */
    private val keep = !Sample.on

    /**
     * Sensitive apps: how many answered the last check. Only the count is kept, never which apps,
     * so the score is still there after a restart (owner, 2026-10-28). Clear history removes it.
     */
    var sensitiveFound by mutableStateOf(if (keep && prefs.contains(SENSITIVE)) prefs.getInt(SENSITIVE, 0) else null)
        private set

    fun recordSensitive(found: Int) {
        sensitiveFound = found
        if (keep) prefs.edit().putInt(SENSITIVE, found).apply()
    }

    fun clearSaved() {
        sensitiveFound = null
        prefs.edit().remove(SENSITIVE).apply()
        history.clear()
    }

    /** The four checks as one score, for the first page. */
    fun overall(context: Context): OverallScore {
        val ticked = context.getSharedPreferences("app", Context.MODE_PRIVATE).getStringSet("checkUpDone", emptySet())!!
        val ids = CheckUp.steps.map { it.id }.toSet()
        val done = phase == Phase.DONE
        return OverallScore.of(
            footprint = if (done) score.value else history.latest?.score,
            sensitiveFound = sensitiveFound,
            watchers = if (done) findings(Section.WATCH).count { it.isConcerning } else null,
            checkUpDone = ticked.intersect(ids).size,
            checkUpTotal = ids.size,
        )
    }

    /**
     * `quietly` re-reads in place, without the scanning screen: when the app comes back to the
     * screen and after the fix walk-through, so a fix shows in the score straight away. A quiet
     * scan is saved to history only when something changed.
     */
    fun scan(quietly: Boolean = false) {
        if (phase == Phase.SCANNING) return
        val before = history.latest
        if (!quietly) phase = Phase.SCANNING
        progress = 0f
        viewModelScope.launch {
            val ctx = getApplication<Application>()
            val readers = Readers.all
            val out = mutableMapOf<String, Reading>()
            readers.forEachIndexed { i, r ->
                val got = withContext(Dispatchers.Default) { runCatching { r.read(ctx) }.getOrDefault(emptyList()) }
                got.forEach { out[it.id] = it }
                progress = (i + 1f) / readers.size
                if (!quietly) delay(60)
            }
            readings = out
            val snapshot = history.snapshot(findings, score)
            val unchanged = before != null && before.score == snapshot.score && before.concerningIds == snapshot.concerningIds
            if (!(quietly && unchanged)) {
                comparison = before?.let { Comparison(it, snapshot) }
                history.append(snapshot)
            }
            phase = Phase.DONE
        }
    }

    /** Re-reads after a permission was granted, without a full rescan animation. */
    fun refresh() {
        viewModelScope.launch {
            val ctx = getApplication<Application>()
            val out = mutableMapOf<String, Reading>()
            for (r in Readers.all) withContext(Dispatchers.Default) { runCatching { r.read(ctx) }.getOrDefault(emptyList()) }.forEach { out[it.id] = it }
            readings = out
        }
    }
}

private const val SENSITIVE = "sensitiveFound"

data class Snapshot(val date: Long, val score: Int, val findingCount: Int, val concerningIds: List<String>, val hashes: Map<String, String>)

data class Comparison(val previous: Snapshot, val current: Snapshot) {
    val changedIds: List<String> get() = current.hashes.filter { (id, h) -> previous.hashes[id] != null && previous.hashes[id] != h }.keys.toList()
}

/**
 * Scan history: the date, score, counts and a salted one-way marker per value, never the values.
 * Stored in no-backup files, so it never leaves the device in a backup either.
 */
class HistoryStore(context: Context) {
    private val dir = context.noBackupFilesDir
    private val file = File(dir, "scan-history.json")
    private val saltFile = File(dir, "scan-history.salt")
    var snapshots: List<Snapshot> = load(); private set
    val latest: Snapshot? get() = snapshots.lastOrNull()

    private val salt: String
        get() = if (saltFile.isFile) saltFile.readText() else (UUID.randomUUID().toString() + UUID.randomUUID()).also { saltFile.writeText(it) }

    fun snapshot(findings: List<Finding>, score: FootprintScore): Snapshot {
        val s = salt
        val hashes = findings.associate { f ->
            val material = s + f.id + "\u001F" + f.reading.value + f.reading.items.joinToString("\u001F")
            f.id to MessageDigest.getInstance("SHA-256").digest(material.toByteArray()).take(8).joinToString("") { "%02x".format(it) }
        }
        return Snapshot(System.currentTimeMillis(), score.value, findings.size, findings.filter { it.isConcerning }.map { it.id }.sorted(), hashes)
    }

    fun append(s: Snapshot) {
        snapshots = (snapshots + s).takeLast(60)
        val arr = JSONArray()
        snapshots.forEach { sn ->
            arr.put(JSONObject().put("date", sn.date).put("score", sn.score).put("count", sn.findingCount)
                .put("concerning", JSONArray(sn.concerningIds)).put("hashes", JSONObject(sn.hashes)))
        }
        file.writeText(arr.toString())
    }

    fun clear() {
        snapshots = emptyList(); file.delete(); saltFile.delete()
    }

    private fun load(): List<Snapshot> = runCatching {
        val arr = JSONArray(file.readText())
        (0 until arr.length()).map { i ->
            val o = arr.getJSONObject(i)
            val h = o.getJSONObject("hashes")
            Snapshot(o.getLong("date"), o.getInt("score"), o.getInt("count"),
                o.getJSONArray("concerning").let { a -> (0 until a.length()).map(a::getString) },
                h.keys().asSequence().associateWith { h.getString(it) })
        }
    }.getOrDefault(emptyList())
}
