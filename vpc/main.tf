/*
  aws의 vpc를 생성하고 생성된 vpc의 이름을 dreamclub으로 지정
  이름은 실제 vpc에 적용되는 것이 아닌 terraform 내부의 식별자로 사용되는 것 같음
*/
resource "aws_vpc" "dreamclub" {
  cidr_block    = "10.0.0.0/16"
  
  // Name에 들어갈 값이 실제 콘솔에서 확인할 수 있는 vpc의 이름이 됨
  tags = {
    Name = "dreamclub"
  }
}

/*
  cidr 범위를 vpc의 cidr 범위 안으로 좁혀야 됨
  보통 가용범위를 2개 이상을 두어 한 쪽 서브넷에서 에러가 발생해도 다른 서브넷에서 서비스를 정상동작 시킬 수 있음
*/
resource "aws_subnet" "dreamclub_first_subnet" {
  vpc_id = aws_vpc.dreamclub.id
  cidr_block = "10.0.1.0/24"

  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "dreamclub-subnet-1"
  }
}

resource "aws_subnet" "dreamclub_second_subnet" {
  vpc_id = aws_vpc.dreamclub.id
  cidr_block = "10.0.2.0/24"

  availability_zone = "ap-northeast-2b"

  tags = {
    Name = "dreamclub-subnet-2"
  }
}

/*
  vpc가 외부와 통신하기 위해 필요한 igw
  igw와 연결된 서브넷은 보통 public subnet이라고 부른다
  따로 igw를 연결하지 않는 이상 서브넷은 보통 private subnet이다
*/
resource "aws_internet_gateway" "dreamclub_igw" {
    vpc_id = aws_vpc.dreamclub.id

    tags = {
      Name = "dreamclub_igw"
    }
}
/*
  route table은 트래픽을 규칙에 맞게 전달해주기 위한 규칙을 담는다
  하나의 route table은 여러 개의 subnet에서 사용할 수 있고 이렇게 route table과 subnet을 연결하는 작업을 association이라고 한다
*/
resource "aws_route_table" "dreamclub_route_table" {
  vpc_id = aws_vpc.dreamclub.id

  tags = {
    Name = "dreamclub_route_table"
  }
}


/*
  route_table_association을 사용해서 연결해준다
*/
resource "aws_route_table_association" "dreamclub_route_table_1" {
  subnet_id = aws_subnet.dreamclub_first_subnet.id
  route_table_id = aws_route_table.dreamclub_route_table.id
}

resource "aws_route_table_association" "dreamclub_route_table_2" {
  subnet_id = aws_subnet.dreamclub_second_subnet.id
  route_table_id = aws_route_table.dreamclub_route_table.id
}

/*
  terraform은 resource의 update가 이루어져야 할 때, update에 제약이 있으면
  해당 resource를 삭제 후, update된 resource를 생성한다.

  이는 먼저 resource가 삭제되기 때문에 update된 resource가 생성되기 전까지 기능을 하지 못하는 상황이 생길 수 있다.
  특히, 외부에 보여지는 정보들은 타격이 더 크기 때문에 보통 create_before_destroy 옵션을 사용해서
  삭제되기 전에 update된 resource를 먼저 생성하고, 그 다음 destroy를 진행한다.

  예를 들어 Elastic ip같은 경우는 변경되면 연결 되어있던 리소스와의 연결이 끊어질 수 있기 때문에 서비스에 좋지 않은 영향을 끼칠 수 있다.
*/
resource "aws_eip" "nat_1" {
  domain = "vpc"

  lifecycle {
    create_before_destroy = true
  }
}

/*
  nat gateway는 public subnet에 위치하지만 private subnet과 연결된다.
  이 때, 의문은 그러면 굳이 eip가 없어도 접근이 쉽지 않은가라고 생각하였으나, 어차피 nat gateway는 외부에서의 접근은 없는 것이고
  내부에서 바로 nat gateway로 연결하여 외부 인터넷과 연결되면 내부 리소스의 정보가 밖으로 나가는 것이기 때문에
  보안 상의 이유라도 eip를 활용하는 것이 좋다고 보인다.
  그리고 nat gateway는 비싸기 때문에 꺼두자
*/