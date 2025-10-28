#!/usr/bin/env node
/**
 * Generate normalized app icon and splash source images from a single branding image.
 *
 * Inputs (auto-detected in assets/branding/):
 *  - boteco-logo.png | boteco-logo.jpg | boteco-logo.jpeg | boteco-logo.svg
 *
 * Outputs:
 *  - assets/app_icons/app_icon.png (1024x1024, white background)
 *  - assets/app_icons/app_icon_foreground.png (1024x1024, transparent BG, black silhouette)
 *  - assets/app_icons/app_icon_monochrome.png (1024x1024, transparent BG, pure black silhouette for Android 13+)
 *  - assets/splash/splash_logo.png (512x512, transparent BG, black silhouette)
 *  - assets/splash/splash_logo_dark.png (512x512, transparent BG, white silhouette)
 *  - assets/splash/splash_logo_android12.png (960x960, transparent BG, black silhouette)
 *  - assets/splash/splash_logo_android12_dark.png (960x960, transparent BG, white silhouette)
 *
 * Notes:
 *  - The script assumes the provided logo is a dark silhouette over a light background.
 *  - It derives an alpha mask by thresholding the luminance, producing clean transparent backgrounds.
 *  - Safe padding and centering are applied to meet Apple/Google visual guidelines.
 */

const path = require('path');
const fs = require('fs');
const fse = require('fs-extra');
const sharp = require('sharp');

// Use repository root regardless of where the script is executed from
const PROJECT_ROOT = path.resolve(__dirname, '..');
const BRAND_DIR = path.join(PROJECT_ROOT, 'assets', 'branding');
const ICONS_DIR = path.join(PROJECT_ROOT, 'assets', 'app_icons');
const SPLASH_DIR = path.join(PROJECT_ROOT, 'assets', 'splash');

const LIGHT_BG = { r: 255, g: 255, b: 255, alpha: 1 }; // #FFFFFF
const DARK_BG = { r: 18, g: 18, b: 18, alpha: 1 }; // #121212

// Canvas sizes
const SIZES = {
  icon: 1024,
  splash: 512,
  android12: 960,
};

// How much of the canvas the logo should occupy (inside fit)
const SCALE = 0.72; // ~72% occupancy to keep safe margins

/** Find the source logo in assets/branding. */
function findSourceLogo() {
  // Accept any image in branding folder with common extensions
  const exts = new Set(['.png', '.jpg', '.jpeg', '.svg']);
  if (!fs.existsSync(BRAND_DIR)) return null;
  const files = fs.readdirSync(BRAND_DIR).filter((f) => exts.has(path.extname(f).toLowerCase()));
  if (files.length === 0) return null;
  // Prefer files that contain 'boteco-logo' in the name, otherwise pick the first
  const preferred = files.find((f) => /boteco[-_ ]?logo/i.test(f));
  const chosen = preferred || files[0];
  return path.join(BRAND_DIR, chosen);
}

/** Create a centered canvas of given size and background color. */
function createCanvas(size, background) {
  return sharp({
    create: {
      width: size,
      height: size,
      channels: 4,
      background,
    },
  });
}

/**
 * Build a silhouette buffer from input image using thresholding.
 * Returns an RGBA buffer with the silhouette filled with the given color and transparent elsewhere.
 */
async function buildSilhouette(inputPath, targetSize, fillColor) {
  // Create alpha mask: silhouette opaque (255), background transparent (0)
  const alphaMask = await sharp(inputPath)
    .removeAlpha() // normalize
    .toColourspace('b-w') // luminance
    .threshold(240) // background becomes white, dark subject becomes black
    .negate() // invert -> subject white, background black
    .resize({
      width: Math.round(targetSize * SCALE),
      height: Math.round(targetSize * SCALE),
      fit: 'inside',
      withoutEnlargement: true,
    })
    .toBuffer();

  // Prepare a solid color layer matching the alpha mask dimensions
  const meta = await sharp(alphaMask).metadata();
  const colorLayer = await sharp({
    create: {
      width: meta.width,
      height: meta.height,
      channels: 3,
      background: fillColor,
    },
  })
    .png()
    .toBuffer();

  // Join alpha channel to the color layer
  const silhouetteRGBA = await sharp(colorLayer).joinChannel(alphaMask).png().toBuffer();
  return silhouetteRGBA;
}

/** Composite silhouette on a canvas with given background. */
async function compositeOnCanvas(silhouetteBuffer, canvasSize, background) {
  const canvas = createCanvas(canvasSize, background);
  const out = await canvas
    .composite([{ input: silhouetteBuffer, gravity: 'center' }])
    .png()
    .toBuffer();
  return out;
}

async function ensureDirs() {
  await fse.ensureDir(ICONS_DIR);
  await fse.ensureDir(SPLASH_DIR);
}

async function main() {
  const input = findSourceLogo();
  if (!input) {
    console.error('ERROR: No source logo found in assets/branding (expected boteco-logo.png/.jpg/.jpeg/.svg).');
    process.exit(1);
  }

  await ensureDirs();

  console.log(`Using source logo: ${path.relative(PROJECT_ROOT, input)}`);

  // Build silhouettes
  const silhouetteBlackIcon = await buildSilhouette(input, SIZES.icon, { r: 0, g: 0, b: 0 });
  const silhouetteBlackSplash = await buildSilhouette(input, SIZES.splash, { r: 0, g: 0, b: 0 });
  const silhouetteBlackAndroid12 = await buildSilhouette(input, SIZES.android12, { r: 0, g: 0, b: 0 });
  const silhouetteWhiteSplash = await buildSilhouette(input, SIZES.splash, { r: 255, g: 255, b: 255 });
  const silhouetteWhiteAndroid12 = await buildSilhouette(input, SIZES.android12, { r: 255, g: 255, b: 255 });

  // Foreground icon (adaptive foreground) - transparent BG, black silhouette
  const appIconForeground = await compositeOnCanvas(silhouetteBlackIcon, SIZES.icon, { r: 0, g: 0, b: 0, alpha: 0 });
  await sharp(appIconForeground).toFile(path.join(ICONS_DIR, 'app_icon_foreground.png'));

  // Full icon for iOS/non-adaptive - white BG, black silhouette
  const appIconFull = await compositeOnCanvas(silhouetteBlackIcon, SIZES.icon, LIGHT_BG);
  await sharp(appIconFull).toFile(path.join(ICONS_DIR, 'app_icon.png'));

  // Monochrome variant (Android 13+) - transparent BG, pure black silhouette
  const appIconMonochrome = await compositeOnCanvas(silhouetteBlackIcon, SIZES.icon, { r: 0, g: 0, b: 0, alpha: 0 });
  await sharp(appIconMonochrome).toFile(path.join(ICONS_DIR, 'app_icon_monochrome.png'));

  // Splash logos (transparent BG)
  const splashLight = await compositeOnCanvas(silhouetteBlackSplash, SIZES.splash, { r: 0, g: 0, b: 0, alpha: 0 });
  await sharp(splashLight).toFile(path.join(SPLASH_DIR, 'splash_logo.png'));

  const splashDark = await compositeOnCanvas(silhouetteWhiteSplash, SIZES.splash, { r: 0, g: 0, b: 0, alpha: 0 });
  await sharp(splashDark).toFile(path.join(SPLASH_DIR, 'splash_logo_dark.png'));

  // Android 12 specific icons (transparent BG, background defined by flutter_native_splash)
  const splashAndroid12Light = await compositeOnCanvas(silhouetteBlackAndroid12, SIZES.android12, { r: 0, g: 0, b: 0, alpha: 0 });
  await sharp(splashAndroid12Light).toFile(path.join(SPLASH_DIR, 'splash_logo_android12.png'));

  const splashAndroid12Dark = await compositeOnCanvas(silhouetteWhiteAndroid12, SIZES.android12, { r: 0, g: 0, b: 0, alpha: 0 });
  await sharp(splashAndroid12Dark).toFile(path.join(SPLASH_DIR, 'splash_logo_android12_dark.png'));

  console.log('Brand assets generated successfully under assets/app_icons and assets/splash.');
}

main().catch((err) => {
  console.error('Failed to generate brand assets:', err);
  process.exit(1);
});