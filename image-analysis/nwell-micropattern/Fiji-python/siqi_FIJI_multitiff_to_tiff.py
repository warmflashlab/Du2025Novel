from ij import IJ
import os
import shutil
"""
--------------------------------------------------------------
Helper Functions
--------------------------------------------------------------
"""


def get_filename(path):
    return os.path.basename(path).split('.')[0]


def get_tiffs_in_directory(path):
    images = []
    for entry in os.listdir(path):
        entry_path = os.path.join(path, entry)
        if os.path.isfile(entry_path) and entry.endswith(".tif"):
            images.append(entry_path)

    images.sort()
    return images


def get_image_bioformats(filename):
    importer_parameters = [
        "open=[{}]".format(filename), "color_mode=Default", "view=Hyperstack",
        "stack_order=XYCZT"
    ]

    macro_string = """
    run("Bio-Formats Importer", "{}");
    """.format(' '.join(importer_parameters))

    IJ.runMacro(macro_string)
    return IJ.getImage()


def save_selected_image(filename):
    image = IJ.getImage()
    IJ.saveAsTiff(image, filename)


"""
--------------------------------------------------------------
GLOBAL PARAMETERS
--------------------------------------------------------------
"""

INPUT_PATH = "/home/zak/Downloads/siqi/test"
OUTPUT_PATH = "/home/zak/Downloads/siqi/output"

if not os.path.exists(OUTPUT_PATH):
    os.mkdir(OUTPUT_PATH)
"""
--------------------------------------------------------------
Main Script
--------------------------------------------------------------
"""

for image_name in get_tiffs_in_directory(INPUT_PATH):
    print("Processing {}".format(image_name))
    image_loaded = get_image_bioformats(image_name)
    filename = get_filename(image_name)
    output_filename = os.path.join(OUTPUT_PATH, filename)
    save_selected_image(output_filename)
    image_loaded.close()

print("Done")
