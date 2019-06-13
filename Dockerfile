# 1
FROM vapor/swift:5.0

# 2
WORKDIR /package
# 3
COPY . ./
# 4
RUN swift package resolve
RUN swift package clean
# 5
CMD ["swift", "test"]