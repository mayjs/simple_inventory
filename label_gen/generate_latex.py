from argparse import ArgumentParser
from itertools import product

TEMPLATE="""
    \\begin{{textblock*}}{{{width}mm}}({xpos}mm,{ypos}mm)
        \\begin{{minipage}}[t][{height}mm][t]{{\\textwidth}}
        \\topskip0pt
        \\vspace*{{\\fill}}
        \\includegraphics[height=25mm]{{{imgfile}}}
        \\vspace*{{\\fill}}
        %
        \\end{{minipage}}
    \\end{{textblock*}}
"""


# Left inset: 6mm
# Top inset: 13
# Sticker width:66mm
# Sticker height:34mm

if __name__ == "__main__":
    parser = ArgumentParser(description="This tool generates latex templates for printable labels. All units in mm! Defaults are made for HERMA 4389")
    parser.add_argument("-x", help="The x offset of the labels", default=6)
    parser.add_argument("-y", help="The y offset of the labels", default=13)
    parser.add_argument("-sw", "--sticker_width", default=66)
    parser.add_argument("-sh", "--sticker_height", default=34)
    parser.add_argument("-w", "--width", help="Number of stickers on the x axis", default=3)
    parser.add_argument("-H", "--height", help="Number of stickers on the y axis", default=8)
    parser.add_argument("-f", "--image_files", help="A python format string mapping indices to image files (default: 'codes/{idx:02}')", default="codes/{idx:02}")

    parser.add_argument("output", help="The output tex file")

    args = parser.parse_args()

    output = ""
    for (i, (y, x)) in enumerate(product(list(range(args.height)), list(range(args.width)))):
        output += TEMPLATE.format(width=args.sticker_width, height=args.sticker_height,
                                  xpos=args.x+x*args.sticker_width, ypos=args.y+y*args.sticker_height,
                                  imgfile=args.image_files.format(idx=i))
        output += "\n"

    with open(args.output, "w") as f:
        f.write(output)
