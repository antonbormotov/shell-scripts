require 'aws-sdk'

Aws.config.update({
  region: 'AWS-REGION',
  credentials: Aws::Credentials.new(
    'ACCESS_KEY',
    'SECRET_ACCESS_KEY'
  )
})
bucket_name = 'BUCKET_NAME_HERE'

s3 = Aws::S3::Resource.new
s3.bucket(bucket_name).objects.each do |object|
  puts object.key
  object.acl.put({ acl: 'public-read' })
end
