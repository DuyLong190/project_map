package com.example.project_map

import android.app.Application
import com.google.android.libraries.places.api.Places

class App : Application() {
    override fun onCreate() {
        super.onCreate()
        
        // Initialize Places API
        if (!Places.isInitialized()) {
            // Get API key from manifest or use default
            val apiKey = "AIzaSyBJecgZLfDTdBejPAUVKtZIotX036OvIdA"
            Places.initialize(applicationContext, apiKey)
        }
    }
}
