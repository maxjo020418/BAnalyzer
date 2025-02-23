from pyspark.sql import SparkSession
from pyspark.sql.functions import explode, split, col, sum as spark_sum
import random

# Initialize Spark Connect session
spark = SparkSession.builder.remote("sc://localhost:15002") \
    .appName("SparkConnectApp") \
    .getOrCreate()


def test_word_count():
    print("Running Word Count Test with DataFrames...")
    # Create a DataFrame with sample sentences
    sentences = [("Spark is amazing",),
                 ("Spark connects with Python",),
                 ("Big Data with Spark and PySpark",)]
    df = spark.createDataFrame(sentences, ["sentence"])

    # Split sentences into words and explode the list into rows
    words_df = df.select(explode(split(col("sentence"), " ")).alias("word"))

    # Group by words and count the occurrences
    word_counts = words_df.groupBy("word").count().orderBy("count", ascending=False)
    word_counts.show()


def test_dataframe_aggregation():
    print("Running DataFrame Aggregation Test...")
    # Create a DataFrame with random data
    data = [(i, random.randint(1, 10)) for i in range(1, 101)]
    df = spark.createDataFrame(data, ["id", "category"])

    # Group by 'category' and count the number of records per group
    agg_df = df.groupBy("category").count().orderBy("count", ascending=False)
    agg_df.show()


def test_computation_heavy_job():
    print("Running Computation Heavy Job Test with DataFrames...")
    # Generate a DataFrame with numbers from 1 to 999999 using spark.range
    df = spark.range(1, 1000000).withColumnRenamed("id", "number")

    # Compute the square of each number
    df = df.withColumn("square", col("number") * col("number"))

    # Aggregate the sum of squares
    result = df.select(spark_sum("square").alias("sum_of_squares")).collect()[0]["sum_of_squares"]
    print("Sum of squares from 1 to 999999 is:", result)


if __name__ == "__main__":
    test_word_count()
    test_dataframe_aggregation()
    test_computation_heavy_job()
