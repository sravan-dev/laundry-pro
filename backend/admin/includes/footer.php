    </main>
</div>

<script>
// Auto-close alerts
setTimeout(() => {
    document.querySelectorAll('.alert-auto').forEach(el => el.remove());
}, 3500);

// Confirm delete
function confirmDelete(form) {
    if (confirm('Are you sure you want to delete this record? This action cannot be undone.')) {
        form.submit();
    }
}
</script>
</body>
</html>
