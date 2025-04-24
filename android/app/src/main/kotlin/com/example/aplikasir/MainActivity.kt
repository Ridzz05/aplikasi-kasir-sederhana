package com.example.aplikasir

import android.os.Bundle
import com.google.gson.GsonBuilder
import com.google.gson.stream.JsonReader
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Konfigurasi Gson agar lebih lenient terhadap malformed JSON
        val gson = GsonBuilder().setLenient().create()
    }
}
