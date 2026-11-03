"use client";

import { useEffect, useRef } from "react";

type MagicRevealProps = {
  original: string;
  magic: string;
  onBack: () => void;
  onNew: () => void;
};

export function MagicReveal({ original, magic, onBack, onNew }: MagicRevealProps) {
  const dialogRef = useRef<HTMLDivElement>(null);
  const extension = magic.startsWith("data:image/png")
    ? "png"
    : magic.startsWith("data:image/webp")
      ? "webp"
      : "jpg";

  useEffect(() => {
    dialogRef.current?.focus();
    function onKey(event: KeyboardEvent) {
      if (event.key === "Escape") onBack();
    }
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [onBack]);

  return (
    <div className="reveal">
      <div
        className="reveal-card"
        role="dialog"
        aria-modal="true"
        aria-labelledby="reveal-title"
        tabIndex={-1}
        ref={dialogRef}
      >
        <p className="eyebrow">It came to life</p>
        <h2 id="reveal-title">Your drawing, for real</h2>
        <div className="compare">
          <figure className="magic-figure">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img className="magic-photo" src={magic} alt="Realistic magical version of the drawing" />
            <figcaption>The magic version</figcaption>
          </figure>
          <figure className="original-figure">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img src={original} alt="The original drawing" />
            <figcaption>Your drawing</figcaption>
          </figure>
        </div>
        <div className="reveal-actions">
          <a className="magic save" href={magic} download={`movo-draw.${extension}`}>
            Save picture
          </a>
          <button type="button" className="quiet" onClick={onBack}>
            Keep drawing
          </button>
          <button type="button" className="quiet" onClick={onNew}>
            New drawing
          </button>
        </div>
        <p className="credit">Made with Flux on Replicate</p>
      </div>
    </div>
  );
}
