/**
 * Type definitions for the public API of Disco Science Lite for TypeScriptToLua.
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
   * Options for `DiscoScience.prepareLab()`.
   */
  interface PrepareLabOptions {
    /**
     * Name of [AnimationPrototype](https://lua-api.factorio.com/latest/prototypes/AnimationPrototype.html)
     * to be used as a custom overlay animation.
     */
    animation?: string;
  }

  /**
   * A color in RGBA format.
   *
   * @see https://lua-api.factorio.com/latest/types/Color.html
   */
  type Color =
    | { r?: number; g?: number; b?: number; a?: number }
    | [r: number, g: number, b: number]
    | [r: number, g: number, b: number, a: number];

  /**
   * Runtime interface via `remote.call("DiscoScience", ...)`.
   *
   * Available in `control.lua`.
   *
   * For `typed-factorio` users, this interface is automatically registered via the
   * `declare module "factorio:runtime"` augmentation below.
   *
   * For `factorio-types` users, register manually following your package's convention
   * for typing remote interfaces.
   *
   * Compatible with the original DiscoScience mod interface.
   */
  interface Remote {
    /**
     * Set the scale of a lab overlay at runtime.
     *
     * Works in both the original Disco Science mod and Disco Science Lite.
     * Useful when you want to support both mods with a single `control.lua` code path.
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
 *
 * Compatible with the original DiscoScience mod interface.
 */
declare const DiscoScience: {
  /**
   * `true` when running on Disco Science Lite. `undefined` on the original Disco Science mod.
   *
   * Use this to distinguish between the two mods:
   * ```lua
   * if DiscoScience and DiscoScience.isLite then
   *     -- Disco Science Lite-specific code
   * end
   * ```
   */
  readonly isLite: true;

  /**
   * Exclude a lab prototype from Disco Science colorization.
   *
   * The lab will not receive a color overlay, even when the `Automatic colorization for unsupported mods` setting is enabled.
   *
   * Calling `prepareLab()` on the same lab later removes the exclusion.
   *
   * @param lab Lab to exclude, or its prototype name.
   */
  excludeLab(lab: { type: "lab"; name: string } | string): void;

  /**
   * Prepare a lab prototype for Disco Science colorization.
   *
   * When `options.animation` is omitted, the vanilla lab overlay is used.
   * This preserves compatibility with the original Disco Science mod.
   *
   * To use a custom overlay aligned to your lab's unique shape, specify `options.animation`.
   *
   * @param lab Lab to register for Disco Science colorization.
   * @param options Custom overlay options.
   */
  prepareLab(
    lab: { type: "lab"; name: string },
    options?: DiscoScience.PrepareLabOptions,
  ): void;
};

/**
 * Register the `DiscoScience` remote interface types for `typed-factorio`.
 *
 * This allows `remote.call("DiscoScience", "setIngredientColor", ...)` to be type-checked.
 *
 * If you are using `factorio-types`, this block is harmless.
 */
declare module "factorio:runtime" {
  interface RemoteInterfaceTypes {
    DiscoScience: DiscoScience.Remote;
  }
}
