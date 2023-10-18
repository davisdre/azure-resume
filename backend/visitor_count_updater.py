import os
import azure.functions as func
import pymongo

def main(req: func.HttpRequest) -> func.HttpResponse:
    # Retrieve CosmosDB connection string from environment varaiable
    cosmos_db_connection_string = os.environ["COSMOS_DB_CONNECTION_STRING"]
    
    # Connect to your Azure Cosmos DB account
    client = pymongo.MongoClient(cosmos_db_connection_string)
    database = client["AzureResume"]
    collection = database["Counter"]

    # Increment the visitor count
    result = collection.update_one(
        {"_id": "visitor-count"},
        {"$inc": {"count": 1}},
        upsert=True
    )

    return func.HttpResponse(f"Visitor count updated: {result.modified_count} times.")
