package com.example.project_map

import android.app.Activity
import android.content.Intent
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import com.google.android.libraries.places.api.Places
import com.google.android.libraries.places.api.model.Place
import com.google.android.libraries.places.widget.Autocomplete
import com.google.android.libraries.places.widget.AutocompleteActivity
import com.google.android.libraries.places.widget.model.AutocompleteActivityMode

class PlacesHelper {
    
    companion object {
        fun openPlacesAutocomplete(
            activity: Activity,
            onPlaceSelected: (Place) -> Unit,
            onError: (Exception) -> Unit
        ): ActivityResultLauncher<Intent> {
            
            val launcher = (activity as androidx.activity.ComponentActivity).registerForActivityResult(
                ActivityResultContracts.StartActivityForResult()
            ) { result ->
                when (result.resultCode) {
                    Activity.RESULT_OK -> {
                        val place = Autocomplete.getPlaceFromIntent(result.data!!)
                        onPlaceSelected(place)
                    }
                    AutocompleteActivity.RESULT_ERROR -> {
                        val status = Autocomplete.getStatusFromIntent(result.data!!)
                        onError(Exception("Places API error: ${status.statusMessage}"))
                    }
                    Activity.RESULT_CANCELED -> {
                        // User canceled
                    }
                }
            }
            
            // Create intent for Places Autocomplete
            val fields = listOf(Place.Field.ID, Place.Field.NAME, Place.Field.ADDRESS, Place.Field.LAT_LNG)
            val intent = Autocomplete.IntentBuilder(AutocompleteActivityMode.OVERLAY, fields)
                .setCountry("VN") // Vietnam
                .build(activity)
            
            launcher.launch(intent)
            return launcher
        }
        
        fun createPlacesAutocompleteLauncher(
            activity: Activity,
            onPlaceSelected: (Place) -> Unit,
            onError: (Exception) -> Unit
        ): ActivityResultLauncher<Intent> {
            return openPlacesAutocomplete(activity, onPlaceSelected, onError)
        }
    }
}
