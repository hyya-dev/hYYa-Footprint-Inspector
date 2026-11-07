# Third-party notices

The Apple builds (iPhone, iPad, Mac) contain no third-party code: only Apple's own frameworks.

The Android build bundles the open-source libraries below. All of them are licensed under the
[Apache License, Version 2.0](LICENSES/Apache-2.0.txt). None of them is analytics, advertising,
crash-reporting or networking code, and the Android app holds no internet permission.

Versions are those resolved for the Android release build (`./gradlew :app:dependencies --configuration releaseRuntimeClasspath`).

| Group | Copyright | Artifacts |
|---|---|---|
| `androidx.activity` | The Android Open Source Project | activity-compose 1.13.0, activity-ktx 1.13.0, activity 1.13.0 |
| `androidx.annotation` | The Android Open Source Project | annotation-experimental 1.4.1, annotation-jvm 1.10.0, annotation 1.10.0 |
| `androidx.arch.core` | The Android Open Source Project | core-common 2.2.0, core-runtime 2.2.0 |
| `androidx.autofill` | The Android Open Source Project | autofill 1.0.0 |
| `androidx.collection` | The Android Open Source Project | collection-jvm 1.5.0, collection-ktx 1.5.0, collection 1.5.0 |
| `androidx.compose.animation` | The Android Open Source Project | animation-android 1.12.0, animation-core-android 1.12.0, animation-core 1.12.0, animation 1.12.0 |
| `androidx.compose.foundation` | The Android Open Source Project | foundation-android 1.12.0, foundation-layout-android 1.12.0, foundation-layout 1.12.0, foundation 1.12.0 |
| `androidx.compose.material3` | The Android Open Source Project | material3-android 1.4.0, material3 1.4.0 |
| `androidx.compose.material` | The Android Open Source Project | material-icons-core-android 1.7.8, material-icons-core 1.7.8, material-icons-extended-android 1.7.8, material-icons-extended 1.7.8, material-ripple-android 1.12.0, material-ripple 1.12.0 |
| `androidx.compose.runtime` | The Android Open Source Project | runtime-android 1.12.0, runtime-annotation-android 1.12.0, runtime-annotation 1.12.0, runtime-retain-android 1.12.0, runtime-retain 1.12.0, runtime-saveable-android 1.12.0, runtime-saveable 1.12.0, runtime 1.12.0 |
| `androidx.compose.ui` | The Android Open Source Project | ui-android 1.12.0, ui-geometry-android 1.12.0, ui-geometry 1.12.0, ui-graphics-android 1.12.0, ui-graphics 1.12.0, ui-text-android 1.12.0, ui-text 1.12.0, ui-unit-android 1.12.0, ui-unit 1.12.0, ui-util-android 1.12.0, ui-util 1.12.0, ui 1.12.0 |
| `androidx.compose` | The Android Open Source Project | compose-bom 2026.08.00 |
| `androidx.concurrent` | The Android Open Source Project | concurrent-futures 1.1.0 |
| `androidx.core` | The Android Open Source Project | core-ktx 1.19.0, core-viewtree 1.0.0, core 1.19.0 |
| `androidx.customview` | The Android Open Source Project | customview-poolingcontainer 1.0.0 |
| `androidx.emoji2` | The Android Open Source Project | emoji2 1.4.0 |
| `androidx.graphics` | The Android Open Source Project | graphics-path 1.0.1 |
| `androidx.interpolator` | The Android Open Source Project | interpolator 1.0.0 |
| `androidx.lifecycle` | The Android Open Source Project | lifecycle-common-java8 2.10.0, lifecycle-common-jvm 2.10.0, lifecycle-common 2.10.0, lifecycle-livedata-core-ktx 2.10.0, lifecycle-livedata-core 2.10.0, lifecycle-livedata 2.10.0, lifecycle-process 2.10.0, lifecycle-runtime-android 2.10.0, lifecycle-runtime-compose-android 2.10.0, lifecycle-runtime-compose 2.10.0, lifecycle-runtime-ktx-android 2.10.0, lifecycle-runtime-ktx 2.10.0, lifecycle-runtime 2.10.0, lifecycle-service 2.10.0, lifecycle-viewmodel-android 2.10.0, lifecycle-viewmodel-compose-android 2.10.0, lifecycle-viewmodel-compose 2.10.0, lifecycle-viewmodel-ktx 2.10.0, lifecycle-viewmodel-savedstate-android 2.10.0, lifecycle-viewmodel-savedstate 2.10.0, lifecycle-viewmodel 2.10.0 |
| `androidx.navigationevent` | The Android Open Source Project | navigationevent-android 1.0.0, navigationevent-compose-android 1.0.0, navigationevent-compose 1.0.0, navigationevent 1.0.0 |
| `androidx.profileinstaller` | The Android Open Source Project | profileinstaller 1.4.0 |
| `androidx.room` | The Android Open Source Project | room-common 2.5.0, room-ktx 2.5.0, room-runtime 2.5.0 |
| `androidx.savedstate` | The Android Open Source Project | savedstate-android 1.4.0, savedstate-compose-android 1.4.0, savedstate-compose 1.4.0, savedstate-ktx 1.4.0, savedstate 1.4.0 |
| `androidx.sqlite` | The Android Open Source Project | sqlite-framework 2.3.0, sqlite 2.3.0 |
| `androidx.startup` | The Android Open Source Project | startup-runtime 1.1.1 |
| `androidx.tracing` | The Android Open Source Project | tracing 1.2.0 |
| `androidx.versionedparcelable` | The Android Open Source Project | versionedparcelable 1.1.1 |
| `androidx.window` | The Android Open Source Project | window-core-android 1.5.0, window-core 1.5.0, window 1.5.0 |
| `androidx.work` | The Android Open Source Project | work-runtime-ktx 2.9.1, work-runtime 2.9.1 |
| `com.google.guava` | The Guava Authors | listenablefuture 1.0 |
| `org.jetbrains.kotlin` | JetBrains s.r.o. and Kotlin Programming Language contributors | kotlin-stdlib-common 2.4.20, kotlin-stdlib-jdk7 1.8.0, kotlin-stdlib-jdk8 1.8.0, kotlin-stdlib 2.4.20 |
| `org.jetbrains.kotlinx` | JetBrains s.r.o. and contributors | kotlinx-coroutines-android 1.9.0, kotlinx-coroutines-bom 1.9.0, kotlinx-coroutines-core-jvm 1.9.0, kotlinx-coroutines-core 1.9.0, kotlinx-serialization-bom 1.7.3, kotlinx-serialization-core-jvm 1.7.3, kotlinx-serialization-core 1.7.3 |
| `org.jetbrains` | JetBrains s.r.o. | annotations 23.0.0 |
| `org.jspecify` | The JSpecify Authors | jspecify 1.0.0 |

Licensed under the Apache License, Version 2.0 (the "License"); you may not use these files except in
compliance with the License. You may obtain a copy of the License at
[LICENSES/Apache-2.0.txt](LICENSES/Apache-2.0.txt) or https://www.apache.org/licenses/LICENSE-2.0. Unless required by
applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS"
BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
