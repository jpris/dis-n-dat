from lxml import html
from PIL import Image
import io,requests,sys,os

#Check if download path exists. Prompt user if not
def checkDownloadDirectory(path):

	if (os.path.exists(path)):
		return
	else:
		createPath = input("Path %s doesn't exists. Create directory? (y/n)" % path)
		#If user selects y to create download directory
		if (createPath == "y"):
			createDownloadDirectory(path)
		else:
			sys.exit(0)

#Create download directory and catch errors
def createDownloadDirectory(path):
	try:
		os.mkdir(path)
	except OSError as e:
		print(e)
		sys.exit(1)

#Download image to user specified path
def downloadImage(imageUrl,imageFile,path):
	localFile = path + "\\" + imageFile
	
	print("Downloading image %s" % imageFile)
	try:
		imageToDownload = requests.get(imageUrl+imageFile)
		try:		
			downloadedImage = Image.open(io.BytesIO(imageToDownload.content))
		except IOError as e:
			print(e)
		downloadedImage.save(localFile)
		print("Image downloaded to %s\\%s" % (path, imageFile))

		
	except requests.exceptions.RequestException as e:
		print(e)

#Download video to user specified path
def downloadVideo(videoUrl,videoFile,path):

	localFile = path + "\\" + videoFile

	print("Downloading video %s"% videoFile)
	try:	
		videoToDownload = requests.get(videoUrl, stream=True)
		
		if videoToDownload.status_code == 200:
			with open(localFile, 'wb') as vFile:
				#Write video file to disk as chunks
				for chunk in videoToDownload.iter_content(1024):
					vFile.write(chunk)
		print("Video downloaded to %s\\%s" % (path,videoFile))
	except requests.exceptions.RequestException as e:
		print(e)

#"main" loop		
def getUserMedia(url,path):
	
	#Validate download path
	checkDownloadDirectory(path)
	
	#Flush page variable
	page = None
	
	#Get url source code
	try:
		page = requests.get(url)		
	except requests.exceptions.RequestException as e:
		print(e)

	#Check if page is not loaded	
	if not page:	
		print("Page not Loaded")
		return
	
	#Check if http object status code is not 200/ok
	if not page.status_code == requests.codes.ok:
		print(page.status_code)		
		return
	
	#Parse returned html source
	tree = html.fromstring(page.content)

	#Get image and video file urls
	images = tree.xpath('//meta[contains(@property,"og:image")]/@content')
	videos = tree.xpath('//meta[contains(@property,"og:video")]/@content')
	
	#Get Images
	for img in images:
		img = img.split("?")[0].split("/")
	
		imageFile = img[len(img)-1]
		imageUrl = img[0] + "//" + img[2] + "/" + img[3] + "/"
		
		downloadImage(imageUrl,imageFile,path)
		
		break
	#Get videos
	for video in videos:
		videoFile = video.split("/")[len(video.split("/"))-1]
		print(videoFile)
		downloadVideo(video,videoFile,path)
		
		break


#If run from command line. Require two parameters. Else print help 	
if __name__ == "__main__":
	if (len(sys.argv) == 3):
		getUserMedia(str(sys.argv[1]),str(sys.argv[2]))
	else:
		print("Usage: mediaLoader.py instagram-url path/to/download")