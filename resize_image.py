from PIL import Image

image_path = 'assets/images/logo.png'
output_path = 'assets/images/logo_resized.png'

with Image.open(image_path) as img:
    new_width = int(img.width * 0.8)
    new_height = int(img.height * 0.8)
    resized_img = img.resize((new_width, new_height), Image.Resampling.LANCZOS)
    resized_img.save(output_path)
    print(f"Resized image saved to {output_path}")
