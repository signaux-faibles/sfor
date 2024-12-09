document.addEventListener('DOMContentLoaded', () => {
    const userTimeZone = Intl.DateTimeFormat().resolvedOptions().timeZone;

    if (userTimeZone) {
        fetch('/users/set_time_zone', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
            },
            body: JSON.stringify({ time_zone: userTimeZone })
        }).then(response => {
            if (!response.ok) {
                console.error('Failed to update user time zone');
            }
        }).catch(error => {
            console.error('Error updating user time zone:', error);
        });
    }
});