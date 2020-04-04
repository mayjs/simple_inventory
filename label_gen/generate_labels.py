from argparse import ArgumentParser
from datetime import datetime
from pathlib import Path
import sys
from PIL import Image, ImageDraw, ImageFont
import qrcode
from tqdm import tqdm

if __name__ == "__main__":
    parser = ArgumentParser(description="Generates batches of images for inventory labels")
    parser.add_argument("-n", "--number", help="Number of codes to generate", type=int, required=True)
    parser.add_argument("-b", "--baseurl", help="The prefix for the data", required=True)
    parser.add_argument("output_directory", help="The name of the output directory")
    parser.add_argument("-d", "--data_format", help="The format of the data; defaut: '%%y%%m%%d%%H%%M{counter:02}'", default="%y%m%d%H%M{counter:02}")
    parser.add_argument("-f", "--filename_format", help="The format for output filenames, default: '{:02}.png'", default="{:02}.png")
    parser.add_argument("-l", "--labels", help="Print human readable labels", default=False, action="store_true")
    parser.add_argument("-s", "--labelsize", help="The font size for the label", type=int, default=34)
    parser.add_argument("-lf", "--labelfont", help="The font for the label", default="LiberationSans-Regular")

    args = parser.parse_args()
    out_dir = Path(args.output_directory)
    if not out_dir.exists():
        out_dir.mkdir()
    if not out_dir.is_dir():
        print("Output directory is not a directory", file=sys.stderr)

    timestamp = datetime.now()
    for idx in tqdm(range(args.number)):
        data = timestamp.strftime(args.data_format).format(counter=idx)
        url = args.baseurl + data
        img = qrcode.make(url, border=1)

        font = ImageFont.truetype(args.labelfont, args.labelsize)
        draw = ImageDraw.Draw(img)
        w, h = draw.textsize(data, font=font)
        big_img = Image.new("RGB", (max(w, img.size[0]), img.size[1]+h), "white")
        big_img.paste(img, (max(0, (w-img.size[0])/2),0))
        draw = ImageDraw.Draw(big_img)
        draw.text((max(0, (img.size[0]-w)/2), big_img.size[1]-h), data, font=font, fill="black")

        big_img.save(out_dir / args.filename_format.format(idx))
