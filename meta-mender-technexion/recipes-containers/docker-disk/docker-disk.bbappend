FILES_${PN} += "/data/docker"

do_install[fakeroot] = "1"

TN_CONTAINER_IMAGE_TYPE ?= "tar.gz"
TN_DOCKER_PARTITION_IMAGE ?= "docker-data-partition.img"

fakeroot do_install_append() {
	install -d ${D}/data/docker
	if [ -f ${B}/${TN_DOCKER_PARTITION_IMAGE}.${TN_CONTAINER_IMAGE_TYPE} ]; then
		tar zxf ${B}/${TN_DOCKER_PARTITION_IMAGE}.${TN_CONTAINER_IMAGE_TYPE} -C ${D}/data/docker
	else
		bbfatal "${B}/${TN_DOCKER_PARTITION_IMAGE}.${TN_CONTAINER_IMAGE_TYPE} not found. Please ensure docker-disk exported docker containers directory as tar.gz file correctly."
	fi
}

