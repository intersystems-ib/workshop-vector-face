# workshop-vector-face
Example about an IRIS production using Embedded Python to recognize and identify faces in photos

You can find more in-depth information in https://learning.intersystems.com.

# What do you need to install? 
* [Git](https://git-scm.com/downloads) 
* [Docker](https://www.docker.com/products/docker-desktop) (if you are using Windows, make sure you set your Docker installation to use "Linux containers").
* [Docker Compose](https://docs.docker.com/compose/install/)
* [Visual Studio Code](https://code.visualstudio.com/download) + [InterSystems ObjectScript VSCode Extension](https://marketplace.visualstudio.com/items?itemName=daimor.vscode-objectscript)

# Setup
Build the image we will use during the workshop:

```console
$ git clone https://github.com/intersystems-ib/workshop-vector-face
$ cd workshop-vector-face
$ docker-compose build
```

The current project is self-deployable and it doesn't require further configuration. The Python libraries required are installed during the deployment of the container.

# Workshop

The main purpose of this example is to test the vector search functionality included into InterSystems IRIS from 2024.1 version.

This project works using the IRIS functionality of Embedded Python to identify faces from jpg files in base64, vectorize it and save into a table with a column of Vector type.

We are going to use two models pre-trained to simplify the code, the first one, `mobilenet_graph.pb` will help us to recognize all the faces in our image. The second one, `facenet_keras_weights.h5` will allow us to compare the face found with the faces in the images of our repository.

To test it you can import into your Postman `Vector_search.postman_collection.json`, you'll see two types of HTTP request:
![Postman requests](/assets/postman_requests.png)
* Save...:  POST requests to save faces into the database.
![Save requests](/assets/save_requests.png)
* Check similarity: POSTS requests to get the most close face from the database to the picture sent. 
![Check requests](/assets/check_requests.png)

# How to test it
## First step:
To populate the table with the vector column, launch all save requests in the postman file, InterSystems IRIS will receive and save a person record for each save request.
![Populated table](/assets/populated_table.png)
## Second step:
With the data in our database we can use the vector search functionality sending the check requests. If you want to customize and use your own image you only have to modify the base64 in the body of the request and optionally the name and description of the person. InterSystems IRIS will return the closest person to the image send with the calculated similarity.
![Search result](/assets/search_result.png)