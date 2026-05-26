package com.example.dispersalud_ia

import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen

class MainActivity : FlutterFragmentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {

        val splashScreen = installSplashScreen()

        splashScreen.setKeepOnScreenCondition { false }

        splashScreen.setOnExitAnimationListener { it.remove() }

        super.onCreate(savedInstanceState)
    }
}