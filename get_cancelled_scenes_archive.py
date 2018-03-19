# python script to scrape cancelled scene info from WInSAR collection
# Elena C Reinisch 20170508 
# edit ECR 20170511 add next_token to go to correct page

import requests # access website
from lxml import html # pull information from website
import glob, os # use to manage files
import time # use for date string when naming file

# loop over all current pages in WInSAR's cancelled orders archive
for pagen in range(10, 0, -1):
    # start session
    session_requests = requests.session()

    # set login url as login page leading to page with cancelled orders
    login_url =  "https://winsar.unavco.org/portal/account/login/?next=/portal/tasking/BeingCancelled/?page={}".format(pagen)

    # try accessing the url
    result = session_requests.get(login_url)

    # exit if unsuccessful, otherwise continue
    if not result.ok:
        print("Unable to access url") # Will tell us if the last request was ok
        print("Error code {}".format(result.status_code)) # Will give us the status from the last request
        exit(0)

    # if successful store result
    tree = html.fromstring(result.text)

    # get CSRF token
    authenticity_token = list(set(tree.xpath("//input[@name='csrfmiddlewaretoken']/@value")))[0]

    # get path for next site
    next_token = list(set(tree.xpath("//input[@name='next']/@value")))[0]


    # set website credentials
    payload = {
            "username": "ebaluyut", 
            "password": "Mis51adyM", 
            "csrfmiddlewaretoken": authenticity_token,
            "next": next_token
    }

    # scrape website with given credentials
    result = session_requests.post(
            login_url, 
            data = payload, 
            headers = dict(referer=login_url)
    )

    # remove previous Cancelled Orders files
    #for f in glob.glob("Cancelled_Orders*.txt"):
    #    os.remove(f)

    # print result to text filei with day and time tag
    #filename = "Cancelled_Orders-{}.txt".format(time.strftime("%y%m%d_%H%M"))
    #tmp_file = "tmp.tmp"
    #tmp_out =  open(tmp_file, 'w') 
    #tmp_out.write(result.text)
    #tmp_out.close()

    #filename = "Cancelled_Orders.txt"
    #text_out = open(filename, 'a+') 
    #count = 0
    #for line in open("tmp.tmp"):
    #    if 'd0' in line:
    #       # text_out.write("{} {} {} {}".format(result.text[count + 1], result.text[count + 2], result.text[count + 3], result.text[count + 4]))
    #        #print(result.text[count + 1], result.text[count + 2], result.text[count + 3], result.text[count + 4])
    #        print(line)
    #        print(open("tmp.tmp")[]
    #    count =+ 1
#    print(result.text[1])




    filename = "Cancelled_Orders.tmp"
    print("Successfully acquired material. Printing page {} to {}".format(pagen, filename))
    text_out = open(filename, 'a+') 
    text_out.write(result.text)
    text_out.close()

