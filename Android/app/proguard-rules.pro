# Keep defaults; the app has no reflection-based libraries of its own.

# WorkManager (the scan reminder) opens its Room database by looking up the generated
# WorkDatabase_Impl from WorkDatabase's name. R8 renamed or dropped them, and the release build
# crashed at launch on a Galaxy S25 (2026-10-29): keep both names and the constructor.
-keep class androidx.work.impl.WorkDatabase
-keep class androidx.work.impl.WorkDatabase_Impl { <init>(); }
-keep class * extends androidx.room.RoomDatabase { <init>(); }
