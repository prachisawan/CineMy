from PIL import Image, ImageEnhance

def make_solid_black_background(image_path, target_size=(1024, 1024)):
    try:
        img = Image.open(image_path).convert("RGBA")
        datas = img.getdata()
        
        new_data = []
        for item in datas:
            # item is (r, g, b, a)
            r, g, b = item[0], item[1], item[2]
            
            # Smart Filter inspired by Apple Watch/Fitness icons (Pure Black Background)
            # We want to keep the colorful "Neon Eye" but drop the muddy background.
            
            # Calculate brightness and saturation approximation
            brightness = (r + g + b) / 3
            max_c = max(r, g, b)
            min_c = min(r, g, b)
            saturation = (max_c - min_c) if max_c > 0 else 0
            
            # HEURISTIC:
            # The background pixels in the user's noisy image are likely dark (brightness < 60)
            # AND low saturation (mostly greyish).
            # The LOGO pixels are either bright (brightness > 60) OR highly saturated (colorful).
            
            # If it's dark AND not very colorful, force it to PURE BLACK.
            # We use a gentle fade for antialiasing if we wanted, but for the "solid black" look
            # a hard cutoff usually looks cleaner for these extracted logos.
            
            if brightness < 55 and saturation < 30:
                 # Background noise -> Pure Black
                 new_data.append((0, 0, 0, 255))
            else:
                 # Logo Content -> Keep it
                 new_data.append(item)
        
        img.putdata(new_data)
        
        # Now composite onto a fresh black canvas to be sure
        final_canvas = Image.new("RGBA", target_size, (0, 0, 0, 255))
        
        # Center aspect fit logic (re-using for safety)
        width_ratio = target_size[0] / img.width
        height_ratio = target_size[1] / img.height
        ratio = min(width_ratio, height_ratio)
        new_size = (int(img.width * ratio), int(img.height * ratio))
        
        # High quality resize
        resized_img = img.resize(new_size, Image.Resampling.LANCZOS)
        
        paste_x = (target_size[0] - new_size[0]) // 2
        paste_y = (target_size[1] - new_size[1]) // 2
        
        final_canvas.paste(resized_img, (paste_x, paste_y), resized_img)
        
        final_canvas.save(image_path, "PNG")
        print(f"Successfully applied Watch/Fitness Style Black Background to: {image_path}")
        
    except Exception as e:
        print(f"Error processing image: {e}")

if __name__ == "__main__":
    path = "/Users/prachisawan/Desktop/CineMy/CineMy/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png"
    make_solid_black_background(path)
