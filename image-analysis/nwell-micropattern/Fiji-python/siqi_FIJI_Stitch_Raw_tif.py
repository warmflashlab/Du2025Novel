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


def divide_chunks(l, n):
    # looping till length l
    for i in range(0, len(l), n):
        yield l[i:i + n]


def get_directories_in_directory(path):
    directories = []
    for entry in os.listdir(path):
        entry_path = os.path.join(path, entry)
        if os.path.isdir(entry_path):
            directories.append(entry_path)

    return directories


def get_tiffs_in_directory(path):
    images = []
    for entry in os.listdir(path):
        entry_path = os.path.join(path, entry)
        if os.path.isfile(entry_path) and entry.endswith(".tif"):
            images.append(entry_path)

    images.sort()
    return images


def image_name_to_frame_and_time(image):
    name = get_filename(image)
    splits = name.split('_')   # split on underscores

    if '_t' in name:
        frame = splits[-2][1:]     # Grab second to last component and remove first letter
        time = splits[-1][1:]
        return (int(frame), int(time))
    else:
        frame = splits[-1][1:]
        return (int(frame), 0)     # No time tag, just use zero


def get_image(filename):
    image = IJ.openImage(filename)
    image.show()
    return image


def get_image_bioformats(filename):
    importer_parameters = [
        "open=[{}]".format(filename),
        ]

    macro_string = """
    run("Bio-Formats Importer", "{}");
    """.format(' '.join(importer_parameters))

    IJ.runMacro(macro_string)
    return IJ.getImage()


def save_selected_image(filename):
    image = IJ.getImage()
    IJ.saveAsTiff(image, filename)


def save_selected_image_bioformats(filename):
    exporter_parameters = [
        "save=[{}]".format(filename),
        "export",
        "compression=Uncompressed",
        ]

    macro_string = """
    run("Bio-Formats Exporter", "{}");
    """.format(' '.join(exporter_parameters))

    IJ.runMacro(macro_string)


def stack_to_hyperstack(channels, slices, frames):
    hyperstack_parameters = [
        "order=xyczt(default)",
        "channels={}".format(channels),
        "slices={}".format(slices),
        "frames={}".format(frames),
        "display=Color",
        ]

    macro_string = """
    run("Stack to Hyperstack...", "{}");
    """.format(' '.join(hyperstack_parameters))
    
    IJ.runMacro(macro_string)


def stitch_images(temporary_output, image1, image2):
    print(
        "Opening images to stitch:\n  1. {}\n  2. {}\nOutput file: {}".format(
            image1, image2, temporary_output
            )
        )

    if os.path.exists(temporary_output):
        print("Temporary output already exists! Exiting.")
        return

    image1_open = get_image(image1)
    image2_open = get_image(image2)
    print("Images opened. Running stitch...")

    output_name = get_filename(temporary_output) + ".tif"
    pairwise_parameters = [
        "first_image=[{}]".format(get_filename(image1) + ".tif"),
        "second_image=[{}]".format(get_filename(image2) + ".tif"),
        "fusion_method=[Linear Blending]",
        "fused_image=[{}]".format(output_name),
        "check_peaks=5",
        "compute_overlap",
        "x=0.0000",
        "y=0.0000",
        "z=0.0000",
        "registration_channel_image_1=[Average all channels]",
        "registration_channel_image_2=[Average all channels]",
        "time-lapse_registration=[Register images adjacently over time]",
        "computation=[Save memory (but be slower)]",
        "max/avg=2.50",
        "absolute=3.50",
        ]
    macro_string = """
    run("Pairwise stitching", "{}")
    """.format(' '.join(pairwise_parameters))

    IJ.runMacro(macro_string)
    save_selected_image(temporary_output)

    stitched = IJ.getImage()
    stitched.close()

    image1_open.close()
    image2_open.close()


def combine_images(temporary_output, image1, image2):
    print(
        "Opening images to combine:\n  1. {}\n  2. {}\nOutput file: {}".format(
            image1, image2, temporary_output
            )
        )

    if os.path.exists(temporary_output):
        print("Temporary output already exists! Exiting.")
        return

    image1_open = get_image(image1)
    image2_open = get_image(image2)
    print("Images opened. Running combine...")

    output_name = get_filename(temporary_output) + ".tif"

    concatenate_parameters = [
        "title=[full_output_filename]",
        "keep open",
        "image1=[{}]".format(get_filename(image1) + ".tif"),
        "image2=[{}]".format(get_filename(image2) + ".tif")
        ]

    macro_string = """
    run("Concatenate...", "{}")
    """.format(' '.join(concatenate_parameters))

    IJ.runMacro(macro_string)
    combined = IJ.getImage()
    save_selected_image(temporary_output)

    image1_open.close()
    image2_open.close()
    combined.close()


"""
--------------------------------------------------------------
GLOBAL PARAMETERS
--------------------------------------------------------------
"""

BASE_PATH = "/Volumes/Siqi_life_two/ap-axis-paper/micropatterning-live/20230412/live/"
RAW_PATH_NAME = "images_Raw"
OUTPUT_PATH_NAME = "images_Stitched"
TEMPORARY_OUTPUT_PATH_NAME = "images_Temporary"
N_POS_IN_OBJ = 3

RAW_PATH = os.path.join(BASE_PATH, RAW_PATH_NAME)
TEMPORARY_PATH = os.path.join(BASE_PATH, TEMPORARY_OUTPUT_PATH_NAME)
if not os.path.exists(TEMPORARY_PATH):
    os.mkdir(TEMPORARY_PATH)

OUTPUT_PATH = os.path.join(BASE_PATH, OUTPUT_PATH_NAME)
if not os.path.exists(OUTPUT_PATH):
    os.mkdir(OUTPUT_PATH)
"""
--------------------------------------------------------------
Main Script
--------------------------------------------------------------
"""

total_index = 1
for folder in get_directories_in_directory(RAW_PATH):
    print("Processing folder {}...".format(folder))
    folder_name = get_filename(folder)

    images_to_fuse = {}

    for image in get_tiffs_in_directory(folder):
        f, t = image_name_to_frame_and_time(image)

        if f not in images_to_fuse:
            images_to_fuse[f] = []

        images_to_fuse[f].append(image)

    object_number = 1
    images = sorted(images_to_fuse.keys())
    for chunk in divide_chunks(images, N_POS_IN_OBJ):
        chunk_string = "{}".format(chunk)[1:-1]
        print("Processing images {}...".format(chunk_string))

        first_image = chunk[0]
        n_times = len(images_to_fuse[first_image]) # Number of separate files for each image

        if not all(map(lambda i: len(images_to_fuse[i]) == n_times, chunk)):
            raise RuntimeError("Not all images in chunk have the same number of separate files!")

        first_image_name = get_filename(images_to_fuse[first_image][0]).split(' ')[0]
        image_name = "i{0:04d}_o{1:04d}_".format(total_index, object_number) + first_image_name + " PM.tif"
        final_image_path = os.path.join(OUTPUT_PATH, image_name)

        if os.path.exists(final_image_path):
            print("Output file {} already exists, skipping work...".format(final_image_path))
            object_number += 1
            total_index += 1
            continue

        to_fuse = []
        czts = []
        previous = chunk[0]
        for i in range(n_times):
            stitched = images_to_fuse[first_image][i]

            # Store XYZCT information for this time chunk
            bfimage = get_image_bioformats(stitched)
            xyczt = bfimage.getDimensions()
            bfimage.close()
            
            print("Retrieved CZT for first image: c:{} z:{} t:{}".format(*xyczt[2:]))
            czts.append(xyczt[2:])     # only need zct

            for next in chunk[1:]:
                other = images_to_fuse[next][i]
                image_name = "i{}_o{}_stitch_{}__{}__{}x{}.tif".format(total_index, object_number, folder_name, previous, next, i)
                temporary_image_path = os.path.join(TEMPORARY_PATH, image_name)
                stitch_images(temporary_image_path, stitched, other)
                stitched = temporary_image_path
                previous = next

            to_fuse.append(stitched)

        fused = to_fuse[0]
        czt_fuse = czts[0]
        for i, (next_image, czt) in enumerate(zip(to_fuse[1:], czts[1:])):
            image_name = "i{}_o{}_concat_{}_{}_{}.tif".format(total_index, object_number, folder_name, chunk_string.replace(', ', '_'), i)
            temporary_image_path = os.path.join(TEMPORARY_PATH, image_name)
            combine_images(temporary_image_path, fused, next_image)
            czt_fuse[2] += czt[2]  # Add number of time points (channel and Z should be same)
            fused = temporary_image_path

        print("Saving output file to {}...".format(first_image_name))
        object_number += 1
        total_index += 1

        if not os.path.exists(final_image_path):
            final = get_image(fused)
            print("Final CZT for image: c:{} z:{} t:{}".format(*czt_fuse))
            stack_to_hyperstack(*czt_fuse)
            save_selected_image(final_image_path)
            # shutil.copyfile(fused, final_image_path)
            other_image = IJ.getImage()
            other_image.close()
			
print("Done")
