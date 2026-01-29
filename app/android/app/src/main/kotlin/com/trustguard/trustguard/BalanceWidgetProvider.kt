package com.trustguard.trustguard

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class BalanceWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.balance_widget).apply {
                // Get data from SharedPreferences
                // These keys match the ones used in WidgetDataService.dart
                val netBalance = widgetData.getString("widget_net_balance", "$0.00")
                val owed = widgetData.getString("widget_owed", "Owed: $0.00")
                val owing = widgetData.getString("widget_owing", "Owing: $0.00")
                val groupCount = widgetData.getString("widget_group_count", "")
                val lastUpdated = widgetData.getString("widget_last_updated", "")

                setTextViewText(R.id.widget_net_balance, netBalance)
                setTextViewText(R.id.widget_owed, owed)
                setTextViewText(R.id.widget_owing, owing)
                setTextViewText(R.id.widget_group_count, groupCount)
                setTextViewText(R.id.widget_update_time, lastUpdated)

                // Deep link to app when tapping the widget
                val singleGroupId = widgetData.getString("widget_single_group_id", "")
                val uriStr = if (singleGroupId?.isNotEmpty() == true) {
                    "trustguard://groups/$singleGroupId"
                } else {
                    "trustguard://groups"
                }

                val intent = Intent(Intent.ACTION_VIEW, Uri.parse(uriStr))
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
