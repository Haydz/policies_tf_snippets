resource "aws_ebs_volume" "volume" {

// Here , We need to give same AZ as the INstance Have.
    availability_zone = aws_instance.public_test_instance.availability_zone

// Size IN GiB
    size = 20

    tags = {

        Name = "ebsviaTF"
    }    
}

resource "aws_volume_attachment" "ebsAttach" {

    device_name = "/dev/sdp"
    volume_id = aws_ebs_volume.volume.id
    instance_id = aws_instance.public_test_instance.id

}
