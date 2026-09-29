"""`flutter create .` dan keyin ruxsatlarni AndroidManifest va Info.plist ga qo'shadi.

Ishlatish (loyiha papkasida):
    flutter create . --org uz.ustabonus --project-name usta_bonus --platforms android,ios
    python3 tool/setup_platforms.py
"""
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent

ANDROID_PERMS = [
    "android.permission.CAMERA",
    "android.permission.ACCESS_FINE_LOCATION",
    "android.permission.ACCESS_COARSE_LOCATION",
]

IOS_KEYS = {
    "NSCameraUsageDescription":
        "Stikerdagi QR-kodni skanerlash va o'rnatilgan radiatorni suratga olish uchun",
    "NSPhotoLibraryUsageDescription":
        "O'rnatilgan radiator fotosini galereyadan tanlash uchun",
    "NSLocationWhenInUseUsageDescription":
        "O'rnatish manzilini aniqlash uchun",
}


def patch_android() -> None:
    path = ROOT / "android/app/src/main/AndroidManifest.xml"
    if not path.exists():
        print("AndroidManifest.xml topilmadi, o'tkazib yuborildi")
        return
    text = path.read_text(encoding="utf-8")
    lines = "".join(
        f'    <uses-permission android:name="{p}" />\n'
        for p in ANDROID_PERMS
        if p not in text
    )
    if lines:
        text = re.sub(r"(<manifest[^>]*>\n)", lambda m: m.group(1) + lines, text, count=1)
        path.write_text(text, encoding="utf-8")
    # Ilova nomi
    text = path.read_text(encoding="utf-8")
    text = re.sub(r'android:label="[^"]*"', 'android:label="Usta Bonus"', text, count=1)
    path.write_text(text, encoding="utf-8")
    print("Android ruxsatlari qo'shildi")


def patch_ios() -> None:
    path = ROOT / "ios/Runner/Info.plist"
    if not path.exists():
        print("Info.plist topilmadi, o'tkazib yuborildi")
        return
    text = path.read_text(encoding="utf-8")
    extra = "".join(
        f"\t<key>{k}</key>\n\t<string>{v}</string>\n"
        for k, v in IOS_KEYS.items()
        if k not in text
    )
    if extra:
        idx = text.rfind("</dict>")
        text = text[:idx] + extra + text[idx:]
        path.write_text(text, encoding="utf-8")
    print("iOS ruxsatlari qo'shildi")


if __name__ == "__main__":
    patch_android()
    patch_ios()
