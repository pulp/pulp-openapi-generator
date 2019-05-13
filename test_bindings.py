from pulpcore.client.pulpcore import (ApiClient as CoreApiClient, Artifact, ArtifactsApi,
                                      Configuration, Repository,
                                      RepositoriesApi, TasksApi)
from pulpcore.client.pulp_file import (ApiClient as FileApiClient, ContentApi as FileContentApi, FileContent,
                                       DistributionsApi as FileDistributionsApi, FileDistribution,
                                       PublicationsApi as FilePublicationsApi,
                                       RemotesApi as FileRemotesApi, FileRemote, RepositorySyncURL,
                                       FilePublication)
from pprint import pprint
from time import sleep


def monitor_task(task_href):
    """Polls the Task API until the task is in a completed state.

    Prints the task details and a success or failure message. Exits on failure.

    Args:
        task_href(str): The href of the task to monitor

    Returns:
        list[str]: List of hrefs that identify resource created by the task

    """
    completed = ['completed', 'failed', 'canceled']
    task = tasks.tasks_read(task_href)
    while task.state not in completed:
        sleep(2)
        task = tasks.tasks_read(task_href)
    pprint(task)
    if task.state == 'completed':
        print("The task was successfful.")
        return task.created_resources
    else:
        print("The task did not finish successfully.")
        exit()


# Configure HTTP basic authorization: basic
configuration = Configuration()
configuration.username = 'admin'
configuration.password = 'admin'
configuration.safe_chars_for_path_param = '/'

core_client = CoreApiClient(configuration)
file_client = FileApiClient(configuration)

# Create api clients for all resource types
artifacts = ArtifactsApi(core_client)
repositories = RepositoriesApi(core_client)
filecontent = FileContentApi(file_client)
filedistributions = FileDistributionsApi(core_client)
filepublications = FilePublicationsApi(file_client)
fileremotes = FileRemotesApi(file_client)
tasks = TasksApi(core_client)

# Create a File Remote
remote_url = 'https://repos.fedorapeople.org/pulp/pulp/demo_repos/test_file_repo/PULP_MANIFEST'
remote_data = FileRemote(name='bar15', url=remote_url)
file_remote = fileremotes.remotes_file_file_create(remote_data)
pprint(file_remote)

# Create a Repository
repository_data = Repository(name='foo15')
repository = repositories.repositories_create(repository_data)
pprint(repository)

sleep(1)

# Sync a Repository
repository_sync_data = RepositorySyncURL(repository=repository.href)
sync_response = fileremotes.remotes_file_file_sync(file_remote.href, repository_sync_data)

pprint(sync_response)

sleep(1)

# Monitor the sync task
created_resources = monitor_task(sync_response.task)

repository_version_1 = repositories.repositories_versions_read(created_resources[0])
pprint(repository_version_1)
#import pdb;pdb.set_trace()
sleep(1)

# Create an artifact from a local file
artifact = artifacts.artifacts_create(file='test_bindings.py')
pprint(artifact)

sleep(1)

# Create a FileContent from the artifact
file_data = FileContent(relative_path='foo.tar.gz', artifact=artifact.href)
filecontent = filecontent.content_file_files_create(file_data)
pprint(filecontent)

sleep(1)

# Add the new FileContent to a repository version
repo_version_data = {'add_content_units': [filecontent.href]}
repo_version_response = repositories.repositories_versions_create(repository.href, repo_version_data)

sleep(1)

# Monitor the repo version creation task
created_resources = monitor_task(repo_version_response.task)

repository_version_2 = repositories.repositories_versions_read(created_resources[0])
pprint(repository_version_2)

sleep(1)

# Create a publication from the latest version of the repository
publish_data = FilePublication(repository=repository.href)
publish_response = filepublications.publications_file_file_create(publish_data)

sleep(1)

# Monitor the publish task
created_resources = monitor_task(publish_response.task)
publication_href = created_resources[0]

sleep(1)

distribution_data = FileDistribution(name='baz15', base_path='foo15', publication=publication_href)
distribution = filedistributions.distributions_file_file_create(distribution_data)
pprint(distribution)

