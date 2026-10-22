CAR WASH SIMULATOR — Godot 4 Projekt
=====================================

Enthalten:
- Prozedurale 3D-Waschanlage und einfache Fahrzeuge (keine kostenpflichtigen Assets)
- First-Person-Steuerung: PC WASD + Maus
- Touch-Joystick links und Touch-Look auf dem rechten/oberen Bildschirmbereich
- Hochdruckreiniger, Schaum-Modus, Reinigungsfortschritt und Auftragsbelohnungen
- Shop-Upgrade und lokales Speichern

WICHTIG:
Dies ist eine spielbare erste Version mit einfachen prozeduralen Modellen. Es sind keine externen Texturen oder Sounds erforderlich. Wasserstrahl-Partikeleffekte und echte Sounddateien sind für einen späteren Ausbau vorgesehen.

WINDOWS STARTEN
1. Installiere Godot 4.x von https://godotengine.org/download/windows/
2. Entpacke CarWashSimulator.zip in einen normalen Ordner, z. B. C:\Games\CarWashSimulator
3. Starte Godot und klicke auf Import.
4. Wähle die Datei project.godot im entpackten Ordner.
5. Öffne das Projekt und drücke F6 oder F5. (F5 startet das Hauptprojekt.)
6. Desktop-Steuerung: WASD bewegen, Maus umsehen, Escape gibt die Maus frei/zurück.
7. Stelle dich vor das Auto, richte die Kamera auf die Karosserie und drücke SPRÜHEN. Schalte SCHAUM ein, um schneller zu reinigen.
   Die Taste E schaltet den Reiniger ebenfalls um, wenn du nahe genug am Auto bist.

ANDROID EXPORT
1. Installiere Android Studio und darin Android SDK Platform Tools, Android SDK Build-Tools sowie eine passende Android SDK Platform (Godot 4.x Export-Template-Anforderungen beachten).
2. Installiere die Export Templates in Godot: Editor > Manage Export Templates > Download and Install.
3. Godot: Editor > Editor Settings > Export > Android:
   - Android SDK Path auf deinen Android-SDK-Ordner setzen (häufig C:\Users\<Benutzer>\AppData\Local\Android\Sdk)
   - Java SDK Path auf ein installiertes JDK setzen. Für die verwendete Godot-Version die in der Godot-Dokumentation empfohlene JDK-Version nutzen.
4. Project > Export > Add... > Android.
5. Setze einen eindeutigen Package/Unique Name, z. B. com.example.carwashsimulator.
6. Wähle APK als Exportformat (Debug-APK für erste Tests) und klicke Export Project.
7. Kopiere die APK aufs Handy und erlaube bei Bedarf die Installation aus dieser Quelle.

TROUBLESHOOTING
- Wenn Godot einen Parserfehler zeigt, prüfe, ob wirklich Godot 4.x geöffnet ist und alle Dateien aus dem ZIP unverändert vorhanden sind.
- Für die APK müssen Export Templates und Android SDK/JDK konfiguriert sein.
- Das Projekt benötigt keine Plugins und keine bezahlten Assets.
