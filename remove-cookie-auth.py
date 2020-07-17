import json


def recursive_remove(json_dict):
    """
    Recursively search through all of the dictionary and removes any key that is 'cookieAuth'
    """
    for key in list(json_dict):
        if key == 'cookieAuth':
            json_dict.pop(key)
        else:
            value = json_dict[key]
            if isinstance(value, dict):
                # Search this dictionary as well
                recursive_remove(value)
            elif isinstance(value, list):
                recursive_list_search(value)


def recursive_list_search(json_list):
    """
    Recursively search through a passed in list till you hit a dictionary to pass into recursive_remove
    Any other objects are don't cares
    """
    for i in reversed(range(len(json_list))):
        value = json_list[i]
        if isinstance(value, dict):
            recursive_remove(value)
            # Delete the dictionary if it is empty
            if not value:
                del json_list[i]
        elif isinstance(value, list):
            recursive_list_search(value)


# Open the JSON file
api_file = open('api.json', 'r')

# Load the api JSON object into dictionary
api_json = json.load(api_file)

# Close the file
api_file.close()

# Remove 'cookieAuth' from the schema
recursive_remove(api_json)

# Serialize the json
new_api_json_object = json.dumps(api_json)

# Reopen the file in write mode
api_file = open('api.json', 'w')

# Re-write the api.json file
api_file.write(new_api_json_object)

# Close the file
api_file.close()
