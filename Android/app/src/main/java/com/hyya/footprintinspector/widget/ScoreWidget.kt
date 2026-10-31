// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

package com.hyya.footprintinspector.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.text.format.DateUtils
import android.util.SizeF
import android.view.View
import android.widget.RemoteViews
import com.hyya.footprintinspector.MainActivity
import com.hyya.footprintinspector.R

/**
 * The Home Screen widget: the mascot, the overall score and when the last check ran. Holds nothing
 * else: no findings, no app names. Light and dark come from the system through values-night.
 */
class ScoreWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        ids.forEach { manager.updateAppWidget(it, views(context)) }
    }

    companion object {
        const val SCORE = "widgetScore"
        const val CHECKED_AT = "widgetCheckedAt"

        fun update(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, ScoreWidget::class.java))
            if (ids.isNotEmpty()) manager.updateAppWidget(ids, views(context))
        }

        /** Small until the widget is wide enough for the medium layout. */
        private fun views(context: Context): RemoteViews {
            val prefs = context.getSharedPreferences("app", Context.MODE_PRIVATE)
            val score = if (prefs.contains(SCORE)) prefs.getInt(SCORE, 0) else null
            val checkedAt = prefs.getLong(CHECKED_AT, 0)
            return RemoteViews(mapOf(
                SizeF(110f, 140f) to layout(context, R.layout.widget_narrow, score, checkedAt, year = false),
                SizeF(165f, 140f) to layout(context, R.layout.widget_small, score, checkedAt, year = false),
                SizeF(290f, 140f) to layout(context, R.layout.widget_medium, score, checkedAt, year = true),
            ))
        }

        private fun layout(context: Context, id: Int, score: Int?, checkedAt: Long, year: Boolean): RemoteViews {
            val date = DateUtils.FORMAT_SHOW_DATE or DateUtils.FORMAT_ABBREV_MONTH
            // Two lines, so a long date and time stays clear of the mascot.
            val whenChecked = DateUtils.formatDateTime(context, checkedAt, date or (if (year) DateUtils.FORMAT_SHOW_YEAR else DateUtils.FORMAT_NO_YEAR)) + "\n" +
                DateUtils.formatDateTime(context, checkedAt, DateUtils.FORMAT_SHOW_TIME)
            val checked = score != null
            return RemoteViews(context.packageName, id).apply {
                setViewVisibility(R.id.widget_checked, if (checked) View.VISIBLE else View.GONE)
                setViewVisibility(R.id.widget_empty, if (checked) View.GONE else View.VISIBLE)
                if (id == R.layout.widget_narrow) setViewVisibility(R.id.widget_footer, if (checked) View.VISIBLE else View.GONE)
                if (score != null) {
                    setTextViewText(R.id.widget_score, score.toString())
                    setTextViewText(R.id.widget_date, whenChecked)
                }
                val open = Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                setOnClickPendingIntent(android.R.id.background,
                    PendingIntent.getActivity(context, 0, open, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT))
            }
        }
    }
}
