package com.example.njangui

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity (et non FlutterActivity) est requis par local_auth,
// qui affiche l'invite biométrique via un DialogFragment.
class MainActivity : FlutterFragmentActivity()
