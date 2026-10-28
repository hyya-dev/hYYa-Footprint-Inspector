// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

package com.hyya.footprintinspector.remind

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import com.hyya.footprintinspector.MainActivity
import com.hyya.footprintinspector.R
import java.util.concurrent.TimeUnit

/**
 * A reminder to scan again, weekly or monthly, as on iOS. It's a notification scheduled on this
 * device by WorkManager (which survives restarts): no server, nothing sent. Off by default.
 */
enum class ScanReminder(val title: String, val days: Long) {
    OFF("Off", 0), WEEKLY("Every week", 7), MONTHLY("Every month", 30);

    companion object {
        private const val PREF = "scanReminder"
        private const val WORK = "scan-reminder"
        private const val CHANNEL = "reminders"
        const val TITLE = "Time for your privacy check"
        const val BODY = "Restart your device, then open the app: your score updates by itself."

        fun current(c: Context): ScanReminder =
            entries.firstOrNull { it.name == c.getSharedPreferences("app", Context.MODE_PRIVATE).getString(PREF, null) } ?: OFF

        /** Saves the choice and schedules (or cancels) the reminder. */
        fun apply(c: Context, choice: ScanReminder) {
            c.getSharedPreferences("app", Context.MODE_PRIVATE).edit().putString(PREF, choice.name).apply()
            val wm = WorkManager.getInstance(c)
            if (choice == OFF) { wm.cancelUniqueWork(WORK); return }
            val req = PeriodicWorkRequestBuilder<ReminderWorker>(choice.days, TimeUnit.DAYS)
                .setInitialDelay(choice.days, TimeUnit.DAYS).build()
            wm.enqueueUniquePeriodicWork(WORK, ExistingPeriodicWorkPolicy.UPDATE, req)
        }

        fun canNotify(c: Context) =
            c.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED

        fun post(c: Context) {
            if (!canNotify(c)) return
            val nm = c.getSystemService(NotificationManager::class.java)
            nm.createNotificationChannel(NotificationChannel(CHANNEL, "Re-scan reminders", NotificationManager.IMPORTANCE_DEFAULT))
            val open = PendingIntent.getActivity(c, 0,
                Intent(c, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP),
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
            val n = NotificationCompat.Builder(c, CHANNEL)
                .setSmallIcon(R.drawable.ic_notification)
                // The mascot on the notification card.
                .setLargeIcon(android.graphics.BitmapFactory.decodeResource(c.resources, R.drawable.mascot_cutout))
                .setContentTitle(TITLE).setContentText(BODY)
                .setStyle(NotificationCompat.BigTextStyle().bigText(BODY))
                .setContentIntent(open).setAutoCancel(true).build()
            runCatching { NotificationManagerCompat.from(c).notify(1, n) }
        }
    }
}

class ReminderWorker(c: Context, p: WorkerParameters) : Worker(c, p) {
    override fun doWork(): Result { ScanReminder.post(applicationContext); return Result.success() }
}
