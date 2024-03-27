Class Vectorface.WS.Service Extends %CSP.REST
{

Parameter HandleCorsRequest = 0;

Parameter CHARSET = "utf-8";

XData UrlMap [ XMLNamespace = "https://www.intersystems.com/urlmap" ]
{
<Routes>
	<Route Url="/checkSimilarity" Method="POST" Call="CheckSimilarity" />
	<Route Url="/savePhoto" Method="POST" Call="SavePhoto" />    
</Routes>
}

ClassMethod OnHandleCorsRequest(url As %String) As %Status
{
	set url = %request.GetCgiEnv("HTTP_REFERER")
    set origin = $p(url,"/",1,3) // origin = "http(s)://origin.com:port"

    // here you can check specific origins
    // otherway, it will allow all origins (useful while developing only)

	do %response.SetHeader("Access-Control-Allow-Credentials","true")
	do %response.SetHeader("Access-Control-Allow-Methods","GET,POST,PUT,DELETE,OPTIONS")
	do %response.SetHeader("Access-Control-Allow-Origin",origin)
	do %response.SetHeader("Access-Control-Allow-Headers","Access-Control-Allow-Origin, Origin, X-Requested-With, Content-Type, Accept, Authorization, Cache-Control")
	quit $$$OK
}

ClassMethod CheckSimilarity() As %Status
{
    Try {
        Do ##class(%REST.Impl).%SetContentType("application/json")
        If '##class(%REST.Impl).%CheckAccepts("application/json") Do ##class(%REST.Impl).%ReportRESTError(..#HTTP406NOTACCEPTABLE,$$$ERROR($$$RESTBadAccepts)) Quit
        
        // Reading the body of the http call with the person data
        set dynamicBody = {}.%FromJSON(%request.Content)

        set dynamicStream = dynamicBody.%Get("fileData",,"stream<base64")

        set stream=##class(%Stream.FileBinary).%New()
        set sc=stream.LinkToFile("/shared/durable/"_dynamicBody.fileName)
        set sc=stream.CopyFromAndSave(dynamicStream)

        set imageVector = ..Checker("/shared/durable/"_dynamicBody.fileName)       
        set imageVector = $REPLACE(imageVector, $CHAR(13,10),",")
        set imageVector = $REPLACE(imageVector,"['","")
        set imageVector = $REPLACE(imageVector,"']","")
        set imageVector = $REPLACE(imageVector,"'","")
        set imageVector = $REPLACE(imageVector," ",",")

        set name = ""
        set similarity = ""

        &sql(SELECT TOP 1 name, similarity INTO :name, :similarity  FROM (SELECT name, VECTOR_DOT_PRODUCT(photo, TO_VECTOR(:imageVector, DECIMAL)) AS similarity FROM Vectorface_Data.Person) ORDER BY similarity DESC)

        set result = {"name": "", "similarity":""}
        set result.name = name
        set result.similarity = similarity
        Do ##class(%REST.Impl).%WriteResponse(result.%ToJSON())

        Do ##class(%REST.Impl).%SetStatusCode("200")	
        
    } Catch (ex) {
        Do ##class(%REST.Impl).%SetStatusCode("400")
        return ex.DisplayString()
    }
    Quit $$$OK
}

ClassMethod SavePhoto() As %Status
{
    Try {
        Do ##class(%REST.Impl).%SetContentType("application/json")
        If '##class(%REST.Impl).%CheckAccepts("application/json") Do ##class(%REST.Impl).%ReportRESTError(..#HTTP406NOTACCEPTABLE,$$$ERROR($$$RESTBadAccepts)) Quit
        
        // Reading the body of the http call with the person data
        set dynamicBody = {}.%FromJSON(%request.Content)

        set dynamicStream = dynamicBody.%Get("fileData",,"stream<base64")

        set stream=##class(%Stream.FileBinary).%New()
        set sc=stream.LinkToFile("/shared/durable/"_dynamicBody.fileName)
        set sc=stream.CopyFromAndSave(dynamicStream)

        set imageVector = ..Checker("/shared/durable/"_dynamicBody.fileName)       
        set imageVector = $REPLACE(imageVector, $CHAR(13,10),",")
        set imageVector = $REPLACE(imageVector,"['","")
        set imageVector = $REPLACE(imageVector,"']","")
        set imageVector = $REPLACE(imageVector,"'","")
        set imageVector = $REPLACE(imageVector," ",",")

        &sql(INSERT INTO Vectorface_Data.Person VALUES (:dynamicBody.name, :dynamicBody.description, TO_VECTOR(:imageVector, DECIMAL)))

        Do ##class(%REST.Impl).%SetStatusCode("200")
        Do ##class(%REST.Impl).%WriteResponse(imageVector)
        return {"result": "Picture stored"}
        
    } Catch (ex) {
        Do ##class(%REST.Impl).%SetStatusCode("400")
        Do ##class(%REST.Impl).%WriteResponse(ex.DisplayString())
        return {"errormessage": "Client error"}
    }
    Quit $$$OK
}

ClassMethod Checker(file As %String) As %String [ Language = python ]
{

    import tensorflow as tf
    
    from tensorflow import keras
    
    from tensorflow.keras import backend as K
	
    from keras.models import load_model
	
    from keras_facenet.inception_resnet_v1 import InceptionResNetV1
	
    import cv2
	
    import numpy as np
	
    import matplotlib.pyplot as plt
	
    import os

    # Loading image
    def load_image(FILE):
        return cv2.cvtColor(cv2.imread(f'{FILE}'), cv2.COLOR_BGR2RGB)

    def detect_faces(image, score_threshold=0.7):
        global boxes, scores
        (imh, imw) = image.shape[:-1]
        img = np.expand_dims(image,axis=0)
    
		# Initialize mobilenet
        sess = tf.compat.v1.Session(graph=mobilenet)
        image_tensor = mobilenet.get_tensor_by_name('image_tensor:0')
        boxes = mobilenet.get_tensor_by_name('detection_boxes:0')
        scores = mobilenet.get_tensor_by_name('detection_scores:0')
    
		# Prediction (detection)
        (boxes, scores) = sess.run([boxes, scores], feed_dict={image_tensor:img})
    
    	# Adjusting size of boxes and scores
        boxes = np.squeeze(boxes,axis=0)
        scores = np.squeeze(scores,axis=0)
    
		# Debuging bounding boxes
        idx = np.where(scores>=score_threshold)[0]
    
		# Creation of bounding boxes
        bboxes = []
        for index in idx:
            ymin, xmin, ymax, xmax = boxes[index,:]
            (left, right, top, bottom) = (xmin*imw, xmax*imw, ymin*imh, ymax*imh)
            left, right, top, bottom = int(left), int(right), int(top), int(bottom)
            bboxes.append([left,right,top,bottom])

        return bboxes

    def extract_faces(image,bboxes,new_size=(160,160)):
        cropped_faces = []
        for box in bboxes:
            left, right, top, bottom = box
            face = image[top:bottom,left:right]
            cropped_faces.append(cv2.resize(face,dsize=new_size))
        return cropped_faces

    def compute_embedding(model,face):
        face = face.astype('float32')

        mean, std = face.mean(), face.std()
        face = (face-mean) / std

        face = np.expand_dims(face,axis=0)

        embedding = model.predict(face)
        return embedding

    with tf.io.gfile.GFile("/shared/mobilenet_graph.pb","rb") as f:
        graph_def = tf.compat.v1.GraphDef()
        graph_def.ParseFromString(f.read())
    
    with tf.Graph().as_default() as mobilenet:
        tf.import_graph_def(graph_def,name="")

    facenet = InceptionResNetV1(
        input_shape=(160, 160, 3),
        classes=128,
    )

    facenet.load_weights("/shared/facenet_keras_weights.h5")

    image = load_image(file)
    bboxes = detect_faces(image)
    face = extract_faces(image,bboxes)
    if len(face) > 0 :
        emb = compute_embedding(facenet,face[0])
    
    array = np.array(emb)
    formatted_array = np.vectorize('{:.12f}'.format)(array)
    strArray = "".join(str(x) for x in formatted_array)
    
    return strArray
}

}
