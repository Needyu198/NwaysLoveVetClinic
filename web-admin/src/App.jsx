import React, { useEffect } from 'react';

function managementPortalUrl() {
  if (import.meta.env.VITE_MANAGEMENT_PORTAL_URL) {
    return import.meta.env.VITE_MANAGEMENT_PORTAL_URL;
  }

  const port = import.meta.env.DEV ? '5173' : '8080';
  return `${window.location.protocol}//${window.location.hostname}:${port}`;
}

// Keep the former admin URL useful for bookmarks while authentication and all
// role-specific features live in the unified management portal.
export default function App() {
  const portalUrl = managementPortalUrl();

  useEffect(() => {
    window.location.replace(portalUrl);
  }, [portalUrl]);

  return (
    <div className="login-wrap">
      <div className="login-card">
        <img className="login-logo" src="/logo.png" alt="Nway's Love Vet Clinic" />
        <h1>Management Portal</h1>
        <p>Staff and administrators now use one sign-in page.</p>
        <a className="btn-primary portal-link" href={portalUrl}>Continue to sign in</a>
      </div>
    </div>
  );
}
