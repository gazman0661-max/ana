@tool
extends EditorPlugin
## Android export sirasinda LevelPlay eklentisini otomatik ekler (Android Studio GEREKMEZ):
##  - Java kaynagini res://android/build/src altina kopyalar
##  - AndroidManifest'e eklenti kaydini ve izinleri ekler
##  - LevelPlay + Unity Ads bagimliliklarini Gradle'a ekler
## Gerekli: Project > Install Android Build Template, Export > Android > "Use Gradle Build" ACIK.

var export_plugin: AndroidExportPlugin


func _enter_tree() -> void:
	export_plugin = AndroidExportPlugin.new()
	add_export_plugin(export_plugin)


func _exit_tree() -> void:
	remove_export_plugin(export_plugin)
	export_plugin = null


class AndroidExportPlugin extends EditorExportPlugin:
	const SRC := "res://addons/LevelPlayAds/android_src/com/terlik/levelplayads/LevelPlayAdsPlugin.java"
	const DST_DIR := "res://android/build/src/com/terlik/levelplayads"

	func _get_name() -> String:
		return "LevelPlayAds"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	func _export_begin(features: PackedStringArray, is_debug: bool, path: String, flags: int) -> void:
		if not features.has("android"):
			return
		if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path("res://android/build")):
			push_error("LevelPlayAds: Android build template yok. Project > Install Android Build Template yap.")
			return
		var dst := ProjectSettings.globalize_path(DST_DIR)
		DirAccess.make_dir_recursive_absolute(dst)
		var err := DirAccess.copy_absolute(ProjectSettings.globalize_path(SRC), dst + "/LevelPlayAdsPlugin.java")
		if err != OK:
			push_error("LevelPlayAds: Java dosyasi kopyalanamadi (hata %d). Elle kopyala: android_src/com -> android/build/src/com" % err)
		_patch_gradle()

	# v29: adquality-sdk .aar'i telefonda Jetifier'i patlatiyor (ASCII disi sinif adi).
	# build.gradle'a exclude ekler, gradle.properties'te Jetifier'i kapatir. Tekrar tekrar eklemez.
	func _patch_gradle() -> void:
		var bg := ProjectSettings.globalize_path("res://android/build/build.gradle")
		if FileAccess.file_exists(bg):
			var txt := FileAccess.get_file_as_string(bg)
			if not txt.contains("terlik-exclude-adquality"):
				txt += "\n// terlik-exclude-adquality\nconfigurations.all {\n    exclude group: 'com.unity3d.ads-mediation', module: 'adquality-sdk'\n}\n"
				var f := FileAccess.open(bg, FileAccess.WRITE)
				if f:
					f.store_string(txt)
					f.close()
					print("LevelPlayAds: build.gradle'a adquality exclude eklendi")
				else:
					push_error("LevelPlayAds: build.gradle yazilamadi")
		var gp := ProjectSettings.globalize_path("res://android/build/gradle.properties")
		var lines := PackedStringArray()
		if FileAccess.file_exists(gp):
			for l in FileAccess.get_file_as_string(gp).split("\n"):
				if not l.strip_edges().begins_with("android.enableJetifier"):
					lines.append(l)
		while lines.size() > 0 and lines[lines.size() - 1].strip_edges() == "":
			lines.remove_at(lines.size() - 1)
		lines.append("android.enableJetifier=false")
		if not "\n".join(lines).contains("android.useAndroidX"):
			lines.append("android.useAndroidX=true")
		var g := FileAccess.open(gp, FileAccess.WRITE)
		if g:
			g.store_string("\n".join(lines) + "\n")
			g.close()

	# Eklentiyi Godot'a tanitir
	func _get_android_manifest_application_element_contents(platform: EditorExportPlatform, debug: bool) -> String:
		return '<meta-data android:name="org.godotengine.plugin.v2.LevelPlayAds" android:value="com.terlik.levelplayads.LevelPlayAdsPlugin" />'

	func _get_android_manifest_element_contents(platform: EditorExportPlatform, debug: bool) -> String:
		return '<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />\n<uses-permission android:name="com.google.android.gms.permission.AD_ID" />'

	# Surumleri LevelPlay dokumanindaki guncel degerlerle karsilastir (docs.unity.com > LevelPlay > Android SDK)
	func _get_android_dependencies(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
		return PackedStringArray([
			"com.unity3d.ads-mediation:mediation-sdk:9.5.0",
			# Mediation aglari: panelde actigin her agin adaptorunu buraya ekle.
			"com.unity3d.ads-mediation:unityads-adapter:5.5.0",
			"com.unity3d.ads:unity-ads:4.16.6",
		])
