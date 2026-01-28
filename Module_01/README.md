**Guidance**

How to start:

1. Open the Project in VS Code
2. Navigate to your project root
3. Start PostgreSQL (MANDATORY)

    In VS Code terminal: 
    ```Bash
    docker compose up -d
    ```
4. Open pgAdmin in browser: `http://localhost:8085/`
5. Login using PGADMIN_DEFAULT_EMAIL and PGADMIN_DEFAULT_PASSWORD
6. Start exploring the data and happy querying !!!

How to stop:

1. Simply close the browser tab of `http://localhost:8085`
2. Stop Docker Containers
    
    In VS Code Terminal, from the project root:
    ```Bash
    docker compose down
    ```
3. Exit your VS Code

**Notes**: Keep learning and "stay hungry, stay foolish" !!!