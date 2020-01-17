export MYSQL_CONNECTION=joeylemon:J4Huprat@/golf

all:
	go build -o golf

run:
	./golf

now:
	go build -o golf && ./golf

brun:
	nohup ./golf >golf.log 2>&1 &
