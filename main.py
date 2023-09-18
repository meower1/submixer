import requests
import base64
import time
import os

def main():

    os.system("python3 /root/submixer/Flask/app.py")

    while True:
        with open('urls.txt', 'r') as file:
            file_content = file.read()
            
        urls = file_content.split("\n")

        links = ""
        temp = ""

        for i in urls:
            response = requests.get(i)
            try:
                temp = base64.b64decode(response.text).decode("utf-8")
            except:
                links += response.text
            links += temp


        with open('Flask/templates/goober.html', 'w') as goober:
            goober.write(links)
            goober.close()

        time.sleep(300)

main()