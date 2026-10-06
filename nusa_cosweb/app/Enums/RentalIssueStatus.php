<?php

namespace App\Enums;

enum RentalIssueStatus: string
{
    case Open = 'open';
    case Resolved = 'resolved';
}
