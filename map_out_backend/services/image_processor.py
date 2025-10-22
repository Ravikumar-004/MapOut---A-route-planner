import cv2
import numpy as np
import pytesseract
pytesseract.pytesseract.tesseract_cmd = r"C:\\Program Files\\Tesseract-OCR\\tesseract.exe"


def process_map_image(image_path):
    image = cv2.imread(image_path)
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    edges = cv2.Canny(gray, 100, 200)
    text_data = pytesseract.image_to_data(image, output_type=pytesseract.Output.DICT)

    locations = {
        text_data['text'][i]: (text_data['left'][i], text_data['top'][i])
        for i in range(len(text_data['text'])) if text_data['text'][i].strip() != ""
    }
    return {"edges": edges, "locations": locations, "image": image}
