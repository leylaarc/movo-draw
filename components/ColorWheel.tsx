"use client";

import { useEffect, useRef, useState } from "react";
import { hexToHsv, hsvToHex, hsvToRgb, type Hsv } from "@/lib/color";

const WHEEL_SIZE = 320;

type ColorWheelProps = {
  color: string;
  onChange: (hex: string) => void;
};

export function ColorWheel({ color, onChange }: ColorWheelProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const lastHex = useRef(color.toLowerCase());
  const [hsv, setHsv] = useState<Hsv>(() => hexToHsv(color));

  useEffect(() => {
    const canvas = canvasRef.current;
    const context = canvas?.getContext("2d");
    if (!canvas || !context) return;

    canvas.width = WHEEL_SIZE;
    canvas.height = WHEEL_SIZE;
    const image = context.createImageData(WHEEL_SIZE, WHEEL_SIZE);
    const center = (WHEEL_SIZE - 1) / 2;
    const radius = WHEEL_SIZE / 2;

    for (let y = 0; y < WHEEL_SIZE; y += 1) {
      for (let x = 0; x < WHEEL_SIZE; x += 1) {
        const dx = x - center;
        const dy = y - center;
        const distance = Math.hypot(dx, dy);
        const index = (y * WHEEL_SIZE + x) * 4;
        if (distance > radius) {
          image.data[index + 3] = 0;
          continue;
        }

        let hue = (Math.atan2(dx, -dy) * 180) / Math.PI;
        if (hue < 0) hue += 360;
        const [red, green, blue] = hsvToRgb({
          h: hue,
          s: distance / radius,
          v: 1,
        });
        image.data[index] = red;
        image.data[index + 1] = green;
        image.data[index + 2] = blue;
        image.data[index + 3] = 255;
      }
    }

    context.putImageData(image, 0, 0);
  }, []);

  useEffect(() => {
    if (color.toLowerCase() === lastHex.current) return;
    lastHex.current = color.toLowerCase();
    setHsv(hexToHsv(color));
  }, [color]);

  function commit(next: Hsv) {
    const hex = hsvToHex(next);
    lastHex.current = hex;
    setHsv(next);
    onChange(hex);
  }

  function pick(event: React.PointerEvent<HTMLDivElement>, clamp: boolean) {
    const bounds = event.currentTarget.getBoundingClientRect();
    const dx = event.clientX - bounds.left - bounds.width / 2;
    const dy = event.clientY - bounds.top - bounds.height / 2;
    const radius = bounds.width / 2;
    let distance = Math.hypot(dx, dy);
    if (!clamp && distance > radius) return;
    distance = Math.min(distance, radius);
    let hue = (Math.atan2(dx, -dy) * 180) / Math.PI;
    if (hue < 0) hue += 360;
    commit({
      h: hue,
      s: radius === 0 ? 0 : distance / radius,
      v: hsv.v,
    });
  }

  function onKeyDown(event: React.KeyboardEvent<HTMLDivElement>) {
    const hueStep = 8;
    const satStep = 0.05;
    if (event.key === "ArrowRight") {
      event.preventDefault();
      commit({ ...hsv, h: (hsv.h + hueStep) % 360 });
    } else if (event.key === "ArrowLeft") {
      event.preventDefault();
      commit({ ...hsv, h: (hsv.h - hueStep + 360) % 360 });
    } else if (event.key === "ArrowUp") {
      event.preventDefault();
      commit({ ...hsv, s: Math.min(1, hsv.s + satStep) });
    } else if (event.key === "ArrowDown") {
      event.preventDefault();
      commit({ ...hsv, s: Math.max(0, hsv.s - satStep) });
    }
  }

  const angle = (hsv.h * Math.PI) / 180;
  const knobLeft = 50 + Math.sin(angle) * hsv.s * 46;
  const knobTop = 50 - Math.cos(angle) * hsv.s * 46;
  const bright = hsvToHex({ h: hsv.h, s: hsv.s, v: 1 });

  return (
    <div className="wheel-block">
      <div
        className="wheel"
        role="application"
        tabIndex={0}
        aria-label="Color wheel. Drag to choose a color. Arrow keys change the hue and strength."
        onPointerDown={(event) => {
          event.currentTarget.setPointerCapture(event.pointerId);
          pick(event, false);
        }}
        onPointerMove={(event) => {
          if (!event.currentTarget.hasPointerCapture(event.pointerId)) return;
          pick(event, true);
        }}
        onKeyDown={onKeyDown}
      >
        <canvas ref={canvasRef} aria-hidden="true" />
        <div className="wheel-dim" style={{ opacity: 1 - hsv.v }} />
        <span
          className="wheel-knob"
          style={{ left: `${knobLeft}%`, top: `${knobTop}%`, background: color }}
        />
      </div>
      <label className="tool-label" htmlFor="brightness">
        Brightness
      </label>
      <input
        id="brightness"
        className="brightness"
        type="range"
        min={0}
        max={100}
        value={Math.round(hsv.v * 100)}
        aria-valuemin={0}
        aria-valuemax={100}
        aria-valuenow={Math.round(hsv.v * 100)}
        onChange={(event) => commit({ ...hsv, v: Number(event.target.value) / 100 })}
        style={{ "--track": `linear-gradient(90deg, #241c18, ${bright})` } as React.CSSProperties}
      />
    </div>
  );
}
