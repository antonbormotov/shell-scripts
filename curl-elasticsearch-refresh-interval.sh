#!/bin/sh

DATE=20151206

. config/.env
if [ -z ${ES_HOST} ]
then
    echo "### Cannot source .env file."
    exit 1
fi

echo "### Update refresh interval of product indices..."

ccs="hk id my ph sg th vn"
for cc in $ccs
do
    curl -s -m 5 -k --write-out "\n### Response code: %{http_code}\n" -XPUT -u ${ES_USERNAME}:${ES_PASSWORD} "${ES_HOST}/product_${cc}_${DATE}/_settings" -d '{"index" : {"refresh_interval" : "1m"}}'
    curl -s -m 5 -k --write-out "\n### Response code: %{http_code}\n" -XPUT -u ${ES_USERNAME}:${ES_PASSWORD} "${ES_HOST}/product_${cc}_${DATE}/_settings" -d '{"index" : {"cache": {"query": {"enable": "true"}}}}'
    sleep 1
done
exit 0
