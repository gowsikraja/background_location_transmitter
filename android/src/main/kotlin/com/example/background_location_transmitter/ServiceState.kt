import android.content.Context

object ServiceState {
    fun saveRunning(context: Context, running: Boolean) {
        context.getSharedPreferences("blt_prefs", Context.MODE_PRIVATE)
            .edit()
            .putBoolean("running", running)
            .apply()
    }

    fun isRunning(context: Context): Boolean {
        return context.getSharedPreferences("blt_prefs", Context.MODE_PRIVATE)
            .getBoolean("running", false)
    }
}
