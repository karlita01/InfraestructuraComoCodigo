terraform {
    required_providers{

        docker={
            source="kreuzwerker/docker"
            version="3.0.2"
        }

    }
}

provider "docker"{}

resource "docker_container" "conteiner_ngix"{
    name="nginx"
    image="nginx:latest"
    ports{
        external=3000
        internal=80
    }
}