#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>

// ═══════════════════════════════════════════════════════════════
// THE ANUBIS PROTOCOL — Final Authentication Gateway
//
// The scales of Ma'at demand the True Name AND proof of office.
// Two seals must be spoken to pass the Final Gate.
// ═══════════════════════════════════════════════════════════════

void grant_access() {
    printf("\n\033[1;33m╔══════════════════════════════════════╗\033[0m\n");
    printf("\033[1;33m║        THE TOMB OPENS                ║\033[0m\n");
    printf("\033[1;33m║   Anubis has judged you worthy.       ║\033[0m\n");
    printf("\033[1;33m╚══════════════════════════════════════╝\033[0m\n\n");
    fflush(stdout);
    setuid(0);
    setgid(0);
    char *args[] = {"/bin/sh", "-p", NULL};
    execve("/bin/sh", args, NULL);
}

int main() {
    char buffer[256];
    char office[64];

    printf("\n");
    printf("\033[1;33m╔══════════════════════════════════════╗\033[0m\n");
    printf("\033[1;33m║       THE ANUBIS PROTOCOL v3.7       ║\033[0m\n");
    printf("\033[1;33m║    Final Authentication Gateway       ║\033[0m\n");
    printf("\033[1;33m╚══════════════════════════════════════╝\033[0m\n");
    printf("\n");
    printf("\033[0;36mThe scales of Ma'at require the Secret Name.\033[0m\n");
    printf("\033[0;36mSpeak it now, or be devoured by Ammit.\033[0m\n\n");
    printf("Secret Name: ");
    fflush(stdout);

    // Safe input — no buffer overflow possible
    if (fgets(buffer, sizeof(buffer), stdin) == NULL) {
        return 1;
    }

    // Strip trailing newline/CR
    size_t len = strlen(buffer);
    if (len > 0 && buffer[len - 1] == '\n') buffer[--len] = '\0';
    if (len > 0 && buffer[len - 1] == '\r') buffer[--len] = '\0';

    if (strcmp(buffer, "Kh4s3m_Th3_3t3rn4l_Gu4rd14n_0f_Th3_D34d") == 0) {
        // First seal accepted — demand lore knowledge
        printf("\n\033[0;33mThe first seal is accepted.\033[0m\n");
        printf("\033[0;36mThe 7th scribe stands before me. Who did you replace?: \033[0m");
        fflush(stdout);

        if (fgets(office, sizeof(office), stdin) == NULL) {
            return 1;
        }

        // Strip trailing newline/CR
        len = strlen(office);
        if (len > 0 && office[len - 1] == '\n') office[--len] = '\0';
        if (len > 0 && office[len - 1] == '\r') office[--len] = '\0';

        if (strcmp(office, "Ahmose") == 0) {
            grant_access();
        } else {
            printf("\n\033[0;31m✗ You are not of the Order.\033[0m\n");
            printf("\033[0;31m  The tomb remains sealed.\033[0m\n\n");
        }
    } else {
        printf("\n\033[0;31m✗ The scales tip against you. Access Denied.\033[0m\n");
        printf("\033[0;31m  Ammit hungers...\033[0m\n\n");
    }

    return 0;
}
