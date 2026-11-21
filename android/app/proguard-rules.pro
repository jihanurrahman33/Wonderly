# Flutter's Gradle plugin already keeps what the engine needs. Add app-specific
# keep rules here only when R8 breaks something at runtime.

# flutter_tts calls the platform TextToSpeech service by reflection-free APIs,
# so no extra rules are required today.
