# Product Image Intake Architecture

Product images can come from two places:

- Bundled package assets at `assets/images/<imageName>.png`.
- Runtime-downloaded images saved in app documents at `product_images/<imageName>.png`.

The app checks bundled assets first and falls back to the runtime image cache. Runtime images are useful for collecting missing product images inside the app, but they are not Flutter assets until a developer copies them into `assets/images` and ships a new build.

The in-app "Add image" flow:

1. User pastes an image URL from the product info sheet.
2. The app downloads and validates the image.
3. The app saves it to local app documents using `productNameToImageName(productName)`.
4. The app writes that `imageName` to Firestore through `ProductInfoRepository.editProductInfo`.
5. The app uploads a copy to the Google Drive folder `lush_assets`, creating it if needed.

Developer sync/check flow:

Use `scripts/check_lush_assets.py` to compare the product library, bundled Flutter
assets, and the Google Drive `lush_assets` intake folder. It can report images
that are present in Drive but missing from `assets/images`, and can copy them
into the Flutter asset folder.

Examples:

```sh
python3 scripts/check_lush_assets.py --drive-dir "/path/to/lush_assets"
python3 scripts/check_lush_assets.py --drive-dir "/path/to/lush_assets" --copy-missing
python3 scripts/check_lush_assets.py --rclone-remote "gdrive:lush_assets" --copy-missing
```

On macOS, `scripts/check_lush_assets.command` can be double-clicked and will
prompt for the local/synced `lush_assets` folder path.

Known drawbacks:

- Clearing app data removes runtime-downloaded images until they are re-added or bundled.
- Other devices will know the Firestore `imageName`, but they will not have the local file until the image is bundled or downloaded there too.
- Google Drive is used as a developer intake folder, not as a runtime image CDN.
- The app stores downloaded image bytes as `<imageName>.png` to preserve the current renderer and bundle convention.

## Target-checker depth preview

Tapping a product image in either target-checker card opens a lightweight depth
preview. It reuses the transparent subject cutout from `ProductImageView`. Only
that subject is transformed. A GPU fragment material derives a height field
from the cutout alpha, broad volume, and luminance, then applies 20-step
parallax occlusion, generated surface normals, directional and rim lighting,
specular response, and alpha-fringe cleanup. Shader-generated side walls and a
responsive contact shadow reinforce the silhouette while the backdrop stays
fixed.

On iOS and Android the preview also samples device motion every 8ms and blends
it with touch orbiting. iPhones with ProMotion can render the response above
60Hz because `CADisableMinimumFrameDurationOnPhone` is enabled.

This is intentionally not a Gaussian Splat reconstruction. A catalog entry has
only one source image, whereas a reconstructable splat needs multiple views and
an offline training pipeline. The preview performs no model inference or asset
generation on the phone and adds no 3D package or downloaded payload. Product
PNGs should retain a transparent background so the depth stack follows the
subject silhouette.
