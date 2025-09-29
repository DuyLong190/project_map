package com.example.project_map

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import androidx.activity.result.ActivityResultLauncher
import com.google.android.libraries.places.api.Places
import com.google.android.libraries.places.api.model.Place
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    
    private val CHANNEL = "com.example.project_map/places"
    private var placesLauncher: ActivityResultLauncher<Intent>? = null
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openPlacesAutocomplete" -> {
                    openPlacesAutocomplete { place ->
                        val placeData = mapOf(
                            "id" to place.id,
                            "name" to place.name,
                            "address" to place.address,
                            "latitude" to place.latLng?.latitude,
                            "longitude" to place.latLng?.longitude
                        )
                        result.success(placeData)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
    
    private fun openPlacesAutocomplete(onPlaceSelected: (Place) -> Unit) {
        placesLauncher = PlacesHelper.createPlacesAutocompleteLauncher(
            this,
            onPlaceSelected = onPlaceSelected,
            onError = { exception ->
                // Handle error
                println("Places error: ${exception.message}")
            }
        )
        
        val fields = listOf(Place.Field.ID, Place.Field.NAME, Place.Field.ADDRESS, Place.Field.LAT_LNG)
        val intent = com.google.android.libraries.places.widget.Autocomplete.IntentBuilder(
            com.google.android.libraries.places.widget.model.AutocompleteActivityMode.OVERLAY, 
            fields
        )
            .setCountry("VN")
            .build(this)
        
        placesLauncher?.launch(intent)
    }
}