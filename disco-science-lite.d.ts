/**
 * Type definitions for the public API of Disco Science Lite for TypeScriptToLua users.
 *
 * Works with both `typed-factorio` and `factorio-types` packages through structural compatibility
 * — no direct dependency on either package is required.
 *
 * ## MIT License
 *
 * Copyright (c) 2019 Daniel Brauer
 * Copyright (c) 2026 mokkosu55 a.k.a. nenshoukei
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

/** @noSelfInFile */

declare namespace DiscoScience {
  /**
   * Settings for rendering a lab overlay.
   */
  interface LabOverlaySettings {
    /**
     * Name of
     * [AnimationPrototype](https://lua-api.factorio.com/latest/prototypes/AnimationPrototype.html)
     * to be used as an overlay.
     * If omitted, the built-in overlay for the standard lab shape is used.
     */
    animation?: string;
    /** Scale of the overlay. Default: `1` */
    scale?: number;
  }

  /**
   * A color in RGBA format. Structurally compatible with `typed-factorio`'s `Color` and
   * `factorio-types`'s `Color`, so you can pass values of those types directly.
   *
   * Can be specified as a struct or as a 3- or 4-element tuple `[r, g, b]` / `[r, g, b, a]`.
   * Values are floats; can be 0–1 or 0–255 (interpreted as 0–255 if any value exceeds 1).
   *
   * See: https://lua-api.factorio.com/latest/types/Color.html
   */
  type Color =
    | { r?: number; g?: number; b?: number; a?: number }
    | [r: number, g: number, b: number]
    | [r: number, g: number, b: number, a: number];

  /**
   * Runtime interface via `remote.call("DiscoScience", ...)`.
   *
   * Available in `control.lua`, `control-updates.lua` and `control-final-fixes.lua`.
   *
   * For `typed-factorio` users, this interface is automatically registered via the
   * `declare module "factorio:runtime"` augmentation below.
   *
   * For `factorio-types` users, register manually following your package's convention
   * for typing remote interfaces.
   */
  interface Remote {
    /**
     * Set the scale of a lab overlay.
     *
     * @deprecated Use `DiscoScience.prepareLab()` at the prototype stage instead.
     * This function is kept for compatibility with the original DiscoScience mod.
     *
     * @param lab_name Lab prototype name.
     * @param scale Scale of the overlay. Must be a positive number.
     */
    setLabScale(lab_name: string, scale: number): void;

    /**
     * Set the color of an ingredient (science pack) at runtime.
     *
     * Overrides colors set at prototype stage.
     *
     * @param item_name Item prototype name of the ingredient.
     * @param color Color for the ingredient.
     */
    setIngredientColor(item_name: string, color: Color): void;

    /**
     * Get the color of an ingredient (science pack).
     *
     * @param item_name Item prototype name of the ingredient.
     * @returns Color for the ingredient, or `undefined` if not registered.
     */
    getIngredientColor(item_name: string): Color | undefined;
  }
}

/**
 * Public interface `DiscoScience` for other mods on prototype stage.
 *
 * Usage: `DiscoScience.prepareLab(...)`
 *
 * Available in `data.lua`, `data-updates.lua`, and `data-final-fixes.lua`.
 */
declare const DiscoScience: {
  /**
   * Prepare a lab prototype for Disco Science colorization.
   *
   * `settings` can be used to specify the overlay animation and scale.
   * If not passed, the default settings are used.
   * These settings can be overridden at runtime via `remote.call()`.
   *
   * @param lab Lab prototype to be prepared.
   * @param settings Settings for the lab overlay.
   */
  prepareLab(
    lab: { type: "lab"; name: string },
    settings?: DiscoScience.LabOverlaySettings,
  ): void;

  /**
   * Set the color of an ingredient (science pack) at prototype stage.
   *
   * These colors can be overridden at runtime via `remote.call()`.
   *
   * @param item_name Item prototype name of the ingredient.
   * @param color Color for the ingredient.
   */
  setIngredientColor(item_name: string, color: DiscoScience.Color): void;

  /**
   * Get the color of an ingredient (science pack) registered so far.
   *
   * @param item_name Item prototype name of the ingredient.
   * @returns Color for the ingredient, or `undefined` if not registered.
   */
  getIngredientColor(item_name: string): DiscoScience.Color | undefined;
};

/**
 * Register the `DiscoScience` remote interface types for `typed-factorio`.
 *
 * This allows `remote.call("DiscoScience", "setIngredientColor", ...)` to be type-checked.
 *
 * If you are using `factorio-types`, this block is harmless — it is treated as an ambient
 * module declaration and has no effect on your project.
 */
declare module "factorio:runtime" {
  interface RemoteInterfaceTypes {
    DiscoScience: DiscoScience.Remote;
  }
}
