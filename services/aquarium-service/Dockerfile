# Use the official AWS Lambda base image for Python
FROM public.ecr.aws/lambda/python:3.13

# Copy the requirements file into the image
COPY ./src/requirements.txt ./

# Install the python dependencies
RUN pip install -r requirements.txt

# Copy the source code of the service
COPY ./src/ ./

# Set the command to run the handler
CMD [ "main.handler" ]
